--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Text_IO;

with Ravenscar_Time;

with STM32.Board;
with STM32.Device;
with STM32.GPIO;
with STM32.Setup;
with STM32.User_Button;

with HAL.Bitmap;
with HAL.Framebuffer;
with HAL.I2C;

with Display_ILI9341;
with Bitmapped_Drawing;
with BMP_Fonts;

with AK09940A.I2C_Sensors;

with GUI;

procedure Main is
   use all type GUI.Button_Kind;

   Sensor : AK09940A.I2C_Sensors.AK09940A_Sensor
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#0C#);

   procedure Configure_Sensor;
   --  Restart sensor with new settings according to GUI state

   subtype Sensor_Data is AK09940A.Magnetic_Field_Vector;

   function Read_Sensor return AK09940A.Magnetic_Field_Vector;

   function Min (Left, Right : Sensor_Data)
     return Sensor_Data is
       (X => AK09940A.Magnetic_Field'Min (Left.X, Right.X),
        Y => AK09940A.Magnetic_Field'Min (Left.Y, Right.Y),
        Z => AK09940A.Magnetic_Field'Min (Left.Z, Right.Z));

   function Max (Left, Right : Sensor_Data)
     return Sensor_Data is
       (X => AK09940A.Magnetic_Field'Max (Left.X, Right.X),
        Y => AK09940A.Magnetic_Field'Max (Left.Y, Right.Y),
        Z => AK09940A.Magnetic_Field'Max (Left.Z, Right.Z));

   use type AK09940A.Magnetic_Field;

   function "*" (Percent : Integer; Right : Sensor_Data)
     return Sensor_Data is
       (X => AK09940A.Magnetic_Field'Max
          (abs Right.X / 100, AK09940A.Magnetic_Field'Small) * Percent,
        Y => AK09940A.Magnetic_Field'Max
          (abs Right.Y / 100, AK09940A.Magnetic_Field'Small) * Percent,
        Z => AK09940A.Magnetic_Field'Max
          (abs Right.Z / 100, AK09940A.Magnetic_Field'Small) * Percent);

   function "+" (Left, Right : Sensor_Data)
     return Sensor_Data is
       (X => Left.X + Right.X,
        Y => Left.Y + Right.Y,
        Z => Left.Z + Right.Z);

   type Sensor_Limits is record
      Min : Sensor_Data;
      Max : Sensor_Data;
   end record;

   procedure Make_Wider (Limits : in out Sensor_Limits);
   --  Make limits a bit wider

   procedure Print
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      Data   : AK09940A.Magnetic_Field_Vector);

   procedure Plot
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      X      : Natural;
      Data   : in out Sensor_Data;
      Limits : Sensor_Limits);

   Drive : AK09940A.Sensor_Drive := AK09940A.Ultra_Low_Power_Drive;

   ----------------------
   -- Configure_Sensor --
   ----------------------

   procedure Configure_Sensor is
      use type AK09940A.Sensor_Drive;
      Ok   : Boolean;
      Freq : AK09940A.Measurement_Frequency := 10;
      Drv  : AK09940A.Sensor_Drive := AK09940A.Sensor_Drive'First;
      Map  : constant array (F10 .. F2500) of AK09940A.Measurement_Frequency
        := (10, 20, 50, 100, 200, 400, 1000, 2500);
   begin
      for V of GUI.State (+UL .. +N2) loop
         exit when V;
         Drv := AK09940A.Sensor_Drive'Succ (Drv);
      end loop;

      for F in Map'Range loop
         if GUI.State (+F) then
            Freq := Map (F);
            exit;
         end if;
      end loop;

      if Drive /= Drv then
         Drive := Drv;
         Sensor.Configure
           ((Mode      => AK09940A.Power_Down,
             Drive     => Drive,
             others    => <>),
            Ok);
         pragma Assert (Ok);

         Ravenscar_Time.Delays.Delay_Microseconds (100);
      end if;

      if GUI.State (+SM) then
         Sensor.Configure
           ((Mode      => AK09940A.Single_Measurement,
             Drive     => Drive,
             others    => <>),
            Ok);
      elsif GUI.State (+ST) then
         Sensor.Configure
           ((Mode      => AK09940A.Self_Test,
             Drive     => Drive,
             others    => <>),
            Ok);
      else
         Sensor.Configure
           ((Mode      => AK09940A.Continuous_Measurement,
             Drive     => Drive,
             Frequency => Freq,
             others    => <>),
            Ok);
      end if;

      pragma Assert (Ok);
   end Configure_Sensor;

   ----------------
   -- Make_Wider --
   ----------------

      procedure Make_Wider (Limits : in out Sensor_Limits) is
   begin
      Limits.Min := Limits.Min + (-2) * Limits.Min;
      Limits.Max := Limits.Max + 2 * Limits.Max;
   end Make_Wider;

   -----------
   -- Print --
   -----------

   procedure Print
     (LCD  : not null HAL.Bitmap.Any_Bitmap_Buffer;
      Data : Sensor_Data)
   is
      TX : constant String := AK09940A.Magnetic_Field'Image (Data.X);
      TY : constant String := AK09940A.Magnetic_Field'Image (Data.Y);
      TZ : constant String := AK09940A.Magnetic_Field'Image (Data.Z);
   begin
      if GUI.State (+Fx) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 30),
            Msg        => TX,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Fx).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Fy) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 40),
            Msg        => TY,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Fy).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Fz) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 50),
            Msg        => TZ,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Fz).Color,
            Background => HAL.Bitmap.Black);
      end if;
   end Print;

   ----------
   -- Plot --
   ----------

   procedure Plot
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      X      : Natural;
      Data   : in out Sensor_Data;
      Limits : Sensor_Limits)
   is
      type Int is delta 1.0 range -1000.0 .. 1000.0;
      Height : constant Int := Int (LCD.Height);
      Value  : AK09940A.Magnetic_Field;
      Y      : Natural;
   begin
      Data := Min (Data, Limits.Max);
      Data := Max (Data, Limits.Min);

      if GUI.State (+Fx) then
         Value := (Data.X - Limits.Min.X) / (Limits.Max.X - Limits.Min.X);
         Y := Natural (Value * Height);
         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Fx).Color);
      end if;

      if GUI.State (+Fy) then
         Value := (Data.Y - Limits.Min.Y) / (Limits.Max.Y - Limits.Min.Y);
         Y := Natural (Value * Height);
         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Fy).Color);
      end if;

      if GUI.State (+Fz) then
         Value := (Data.Z - Limits.Min.Z) / (Limits.Max.Z - Limits.Min.Z);
         Y := Natural (Value * Height);
         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Fz).Color);
      end if;
   end Plot;

   -----------------
   -- Read_Sensor --
   -----------------

   function Read_Sensor return AK09940A.Magnetic_Field_Vector is
      Ok     : Boolean;
      Result : AK09940A.Magnetic_Field_Vector;
   begin
      for J in 1 .. 2_000 loop
         exit when Sensor.Is_Data_Ready;
      end loop;

      Sensor.Read_Measurement (Result, Ok);
      pragma Assert (Ok);

      if GUI.State (+SM) then
         --  Restart Single_Measurement
         Sensor.Configure
           ((Mode      => AK09940A.Single_Measurement,
             Drive     => Drive,
             others    => <>),
            Ok);
      elsif GUI.State (+ST) then
         --  Restart Self_Test
         Sensor.Configure
           ((Mode      => AK09940A.Self_Test,
             Drive     => Drive,
             others    => <>),
            Ok);
      end if;

      return Result;
   end Read_Sensor;

   LCD : constant not null HAL.Bitmap.Any_Bitmap_Buffer :=
     STM32.Board.TFT_Bitmap'Access;

   Next_Limits : Sensor_Limits;
begin
   STM32.Board.Initialize_LEDs;
   STM32.User_Button.Initialize;
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Set_Orientation (HAL.Framebuffer.Landscape);
   STM32.Board.Touch_Panel.Initialize;
   STM32.Board.Touch_Panel.Set_Orientation (HAL.Framebuffer.Landscape);

   --  Initialize touch panel IRQ pin
   STM32.Board.TFT_RS.Configure_IO
     ((STM32.GPIO.Mode_In, Resistors => STM32.GPIO.Floating));

   STM32.Setup.Setup_I2C_Master
     (Port        => STM32.Device.I2C_1,
      SDA         => STM32.Device.PB9,
      SCL         => STM32.Device.PB8,
      SDA_AF      => STM32.Device.GPIO_AF_I2C1_4,
      SCL_AF      => STM32.Device.GPIO_AF_I2C1_4,
      Clock_Speed => 400_000);

   declare
      Status : HAL.I2C.I2C_Status;
   begin
      --  Workaround for STM32 I2C driver bug
      STM32.Device.I2C_1.Master_Transmit
        (Addr    => 16#18#,  --  0C * 2
         Data    => (1 => 16#00#),  --  Chip ID for AK09940A
         Status  => Status);
   end;

   --  Look for AK09940A chip
   if not Sensor.Check_Chip_Id then
      Ada.Text_IO.Put_Line ("AK09940A not found.");
      raise Program_Error;
   end if;

   declare
      Ok : Boolean;
   begin
      Sensor.Reset (Ok);
      pragma Assert (Ok);
   end;

   Configure_Sensor;

   --  Predict boundaries from the first sensor measurement
   Next_Limits.Min := Read_Sensor;
   Next_Limits.Max := Next_Limits.Min;
   Make_Wider (Next_Limits);

   loop
      declare
         Data   : AK09940A.Magnetic_Field_Vector;
         Update : Boolean := False;  --  GUI state updated
      begin
         GUI.Draw (LCD.all, Clear => True);  --  draw all buttons

         for X in 0 .. LCD.Width - 1 loop
            STM32.Board.Toggle (STM32.Board.D1_LED);

            Data := Read_Sensor;

            if not STM32.Board.TFT_RS.Set then  --  Touch IRQ Pin is active
               GUI.Check_Touch (STM32.Board.Touch_Panel, Update);
            end if;

            GUI.Draw (LCD.all);

            Next_Limits :=
              (Min => Min (Data, Next_Limits.Min),
               Max => Max (Data, Next_Limits.Max));

            Print (LCD, Data);
            Plot (LCD, X, Data, Next_Limits);

            if Update then
               Configure_Sensor;
               Update := False;
            elsif STM32.User_Button.Has_Been_Pressed then
               GUI.Dump_Screen (LCD.all);
            end if;
         end loop;
      end;
   end loop;
end Main;
