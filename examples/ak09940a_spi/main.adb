--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Real_Time;
with Ada.Text_IO;

with Ravenscar_Time;

with HAL.SPI;

with STM32.Board;
with STM32.Device;
with STM32.EXTI;
with STM32.GPIO;
with STM32.SPI;

with AK09940A.SPI;

with Signals;

procedure Main is
   use type Ada.Real_Time.Time;

   SPI      : STM32.SPI.SPI_Port renames STM32.Device.SPI_2;
   SPI_SCK  : STM32.GPIO.GPIO_Point renames STM32.Device.PB13;
   SPI_MISO : STM32.GPIO.GPIO_Point renames STM32.Device.PB14;
   SPI_MOSI : STM32.GPIO.GPIO_Point renames STM32.Device.PB15;
   SPI_CS   : STM32.GPIO.GPIO_Point renames STM32.Device.PB11;

   package AK09940A_SPI is new AK09940A.SPI
     (SPI_Port => SPI'Access,
      SPI_CS   => SPI_CS'Access);

   procedure Setup_SPI_2;
   procedure Setup_Interrupt;

   -----------------
   -- Setup_SPI_2 --
   -----------------

   procedure Setup_SPI_2 is

      SPI_Pins : constant STM32.GPIO.GPIO_Points :=
        (SPI_SCK, SPI_MISO, SPI_MOSI, SPI_CS);
   begin
      STM32.Device.Enable_Clock (SPI_Pins);

      STM32.GPIO.Configure_IO
        (SPI_CS,
         (Mode        => STM32.GPIO.Mode_Out,
          Resistors   => STM32.GPIO.Floating,
          Output_Type => STM32.GPIO.Push_Pull,
          Speed       => STM32.GPIO.Speed_100MHz));

      STM32.GPIO.Configure_IO
        (SPI_Pins (1 .. 3),
         (Mode           => STM32.GPIO.Mode_AF,
          Resistors      => STM32.GPIO.Pull_Up,
          AF_Output_Type => STM32.GPIO.Push_Pull,
          AF_Speed       => STM32.GPIO.Speed_100MHz,
          AF             => STM32.Device.GPIO_AF_SPI2_5));

      STM32.Device.Enable_Clock (SPI);

      STM32.SPI.Configure
        (SPI,
         (Direction           => STM32.SPI.D2Lines_FullDuplex,
          Mode                => STM32.SPI.Master,
          Data_Size           => HAL.SPI.Data_Size_8b,
          Clock_Polarity      => STM32.SPI.High,   --   Mode 3
          Clock_Phase         => STM32.SPI.P2Edge,
          Slave_Management    => STM32.SPI.Software_Managed,
          Baud_Rate_Prescaler => STM32.SPI.BRP_16,
          First_Bit           => STM32.SPI.MSB,
          CRC_Poly            => 0));
      --  SPI2 sits on APB1, which is 42MHz, so SPI rate in 42/16=2.6MHz
   end Setup_SPI_2;

   PB6    : STM32.GPIO.GPIO_Point renames STM32.Device.PB6;

   Ok     : Boolean := False;
   Vector : array (1 .. 16) of AK09940A.Magnetic_Field_Vector;
   Prev   : Ada.Real_Time.Time;
   Spin   : Natural;

   ---------------------
   -- Setup_Interrupt --
   ---------------------

   procedure Setup_Interrupt is
   begin
      STM32.Device.Enable_Clock (PB6);

      PB6.Configure_IO
        ((Mode     => STM32.GPIO.Mode_In,
          Resistors => STM32.GPIO.Floating));

      PB6.Configure_Trigger (STM32.EXTI.Interrupt_Rising_Edge);
   end Setup_Interrupt;

begin
   STM32.Board.Initialize_LEDs;
   Setup_SPI_2;
   Setup_Interrupt;

   AK09940A_SPI.Initialize (Ok);  --  Disable I2C
   pragma Assert (Ok);

   --  Look for AK09940A chip
   if not AK09940A_SPI.Check_Chip_Id then
      Ada.Text_IO.Put_Line ("AK09940A not found.");
      raise Program_Error;
   end if;

   --  Reset AK09940A
   AK09940A_SPI.Reset (Ok);
   pragma Assert (Ok);

   --  Configure AK09940A
   AK09940A_SPI.Configure
     ((Mode      => AK09940A.Continuous_Measurement,
       Drive     => AK09940A.Ultra_Low_Power_Drive,
       Frequency => 2500,
       others    => <>),
      Ok);
   pragma Assert (Ok);

   loop
      Prev := Ada.Real_Time.Clock;
      Spin   := 0;
      STM32.Board.Toggle (STM32.Board.D1_LED);

      for J in Vector'Range loop

         Signals.Magnetometer.Wait;

         --  Read scaled values from the sensor
         AK09940A_SPI.Read_Measurement (Vector (J), Ok);
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
