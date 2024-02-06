--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Ada.Real_Time;
with Ada.Text_IO;

with Ravenscar_Time;

with STM32.Board;
with STM32.Device;
with STM32.Setup;

with HAL.I2C;

with AK09940A.I2C;

procedure Main is
   use type Ada.Real_Time.Time;

   package AK09940A_I2C is new AK09940A.I2C
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#0C#);

   Ok     : Boolean := False;
   Vector : array (1 .. 16) of AK09940A.Magnetic_Field_Vector;
   Prev   : Ada.Real_Time.Time;
   Spin   : Natural;
begin
   STM32.Board.Initialize_LEDs;
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
         Data    => [16#00#],  --  Chip ID for AK09940A
         Status  => Status);
   end;

   --  Look for AK09940A chip
   if not AK09940A_I2C.Check_Chip_Id (AK09940A.AK09940AA_Chip_Id) then
      Ada.Text_IO.Put_Line ("AK09940A not found.");
      raise Program_Error;
   end if;

   --  Reset AK09940A
   AK09940A_I2C.Reset (Ok);
   pragma Assert (Ok);

   --  Set AK09940A up
   AK09940A_I2C.Configure
     ((Mode      => AK09940A.Continuous_Measurement,
       Drive     => AK09940A.Low_Noise_Drive_1,
       Use_FIFO  => False,
       Frequency => 20),
      Ok);
   pragma Assert (Ok);

   loop
      Prev := Ada.Real_Time.Clock;
      Spin   := 0;
      STM32.Board.Toggle (STM32.Board.D1_LED);

      for J in Vector'Range loop

         while not AK09940A_I2C.Is_Data_Ready loop
            Spin   := Spin + 1;
         end loop;

         --  Read scaled values from the sensor
         AK09940A_I2C.Read_Measurement (Vector (J), Ok);
         pragma Assert (Ok);
      end loop;

      --  Printing...
      declare
         Now  : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
         Diff : constant Duration := Ada.Real_Time.To_Duration (Now - Prev);
      begin
         Ada.Text_IO.New_Line;
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line
           ("Time=" & Diff'Image & "/16 spin=" & Spin'Image);

         for Value of Vector loop
            declare
               X : constant String := Value.X'Image;
               Y : constant String := Value.Y'Image;
               Z : constant String := Value.Z'Image;
            begin
               Ada.Text_IO.Put_Line ("X=" & X & " Y=" & Y & " Z=" & Z);
            end;
         end loop;

         Ada.Text_IO.Put_Line ("Sleeping 2s...");
         Ravenscar_Time.Delays.Delay_Seconds (2);
      end;
   end loop;
end Main;
