--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Ada.Unchecked_Conversion;

package body AK09940A.Internal is

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id
     (Device : Device_Context;
      Expect : Interfaces.Unsigned_8) return Boolean
   is
      Ok   : Boolean;
      Data : Byte_Array (16#00# .. 16#01#);
   begin
      Read (Device, Data, Ok);

      return Ok and Data = [16#48#, Expect];
   end Check_Chip_Id;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Device  : Device_Context;
      Value   : Sensor_Configuration;
      Success : out Boolean)
   is
      use type Interfaces.Unsigned_8;

      type Control_Register is record
         MODE     : Natural range 0 .. 16;
         MT       : Natural range 0 .. 3;
         FIFO     : Boolean;
      end record;

      for Control_Register use record
         MODE     at 0 range 0 .. 4;
         MT       at 0 range 5 .. 6;
         FIFO     at 0 range 7 .. 7;
      end record;

      function Cast_Control is new Ada.Unchecked_Conversion
        (Control_Register, Interfaces.Unsigned_8);

      Mode : constant Natural :=
        (case Value.Mode is
            when Power_Down => 0,
            when Single_Measurement => 1,
            when Continuous_Measurement =>
              (case Value.Frequency is
                  when 10 => 2,
                  when 20 => 4,
                  when 50  => 5,
                  when 100 => 8,
                  when 200 => 10,
                  when 400 => 12),
            when Self_Test => 16);

      MT   : constant Natural := Sensor_Drive'Pos (Value.Drive);
      Data : constant Interfaces.Unsigned_8 :=
        Cast_Control ((MODE => Mode, MT => MT, FIFO => Value.Use_FIFO));
   begin
      Write (Device, 16#32#, Data, Success);
   end Configure;

   -----------------
   -- Disable_I2C --
   -----------------

   procedure Disable_I2C
     (Device  : Device_Context;
      Success : out Boolean) is
   begin
      Write (Device, 16#36#, 2#0001_1011#, Success);
   end Disable_I2C;

   ------------------------
   -- Enable_Temperature --
   ------------------------

   procedure Enable_Temperature
     (Device  : Device_Context;
      Value   : Boolean;
      Success : out Boolean) is
   begin
      Write (Device, 16#31#, (if Value then 64 else 0), Success);
   end Enable_Temperature;

   -------------------
   -- Is_Data_Ready --
   -------------------

   function Is_Data_Ready (Device  : Device_Context) return Boolean is
      use type Interfaces.Unsigned_8;

      Ok   : Boolean;
      Data : Byte_Array (16#10# .. 16#10#);
   begin
      Read (Device, Data, Ok);

      return Ok and (Data (Data'First) and 1) /= 0;
   end Is_Data_Ready;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Device     : Device_Context;
      Value      : out Magnetic_Field_Vector;
      Success    : out Boolean)
   is
      Scale : constant := 2.0 ** 14 / 10_000.0;  --  Sensitivity 10000 LSB/G
      Raw   : Raw_Vector;
   begin
      Read_Raw_Measurement (Device, Raw, Success);

      Value :=
        (X => Magnetic_Field'Small * Integer (Raw.X),
         Y => Magnetic_Field'Small * Integer (Raw.Y),
         Z => Magnetic_Field'Small * Integer (Raw.Z));

      Value :=
        (X => Value.X * Scale,
         Y => Value.Y * Scale,
         Z => Value.Z * Scale);
   end Read_Measurement;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Raw_Measurement
     (Device  : Device_Context;
      Value   : out Raw_Vector;
      Success : out Boolean)
   is
      use Interfaces;

      function Cast is new Ada.Unchecked_Conversion (Unsigned_32, Integer_32);

      function Decode (Data : Byte_Array) return Unsigned_32 is
         (Shift_Left (Unsigned_32 (Data (Data'Last)), 24) +
          Shift_Left (Unsigned_32 (Data (Data'First + 1)), 16) +
          Shift_Left (Unsigned_32 (Data (Data'First)), 8));

      function Decode (Data : Byte_Array) return Integer_32 is
         (Cast (Shift_Right_Arithmetic (Decode (Data), 8)));

      Data : Byte_Array (16#11# .. 16#1B#);
   begin
      Read (Device, Data, Success);

      if Success then
         Value :=
           (X => Decode (Data (16#11# .. 16#13#)),
            Y => Decode (Data (16#14# .. 16#16#)),
            Z => Decode (Data (16#17# .. 16#19#)));

         Success := (Data (16#1B#) and 2) = 0;
      else
         Value := (X | Y | Z => Raw_Magnetic_Field'First);
      end if;
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Device  : Device_Context;
      Success : out Boolean) is
   begin
      Write (Device, 16#33#, 16#01#, Success);
   end Reset;

   -------------------------
   -- Set_FIFO_Water_Mark --
   -------------------------

   procedure Set_FIFO_Water_Mark
     (Device  : Device_Context;
      Value   : Watermark_Level;
      Success : out Boolean) is
   begin
      Write (Device, 16#30#, Interfaces.Unsigned_8 (Value - 1), Success);
   end Set_FIFO_Water_Mark;

end AK09940A.Internal;
