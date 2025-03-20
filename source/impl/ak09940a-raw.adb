--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Unchecked_Conversion;

package body AK09940A.Raw is

   ---------------------
   -- Get_Measurement --
   ---------------------

   function Get_Measurement (Raw  : Byte_Array) return Magnetic_Field_Vector is
      Scale : constant := 2.0 ** 14 / 10_000.0;  --  Sensitivity 10000 LSB/G
      Data  : constant Raw_Vector := Get_Raw_Measurement (Raw);

      Value : constant Magnetic_Field_Vector :=
        (X => Magnetic_Field'Small * Integer (Data.X),
         Y => Magnetic_Field'Small * Integer (Data.Y),
         Z => Magnetic_Field'Small * Integer (Data.Z));
   begin
      return
        (X => Value.X * Scale,
         Y => Value.Y * Scale,
         Z => Value.Z * Scale);
   end Get_Measurement;

   -------------------------
   -- Get_Raw_Measurement --
   -------------------------

   function Get_Raw_Measurement (Raw  : Byte_Array) return Raw_Vector is
      use Interfaces;

      function Cast is new Ada.Unchecked_Conversion (Unsigned_32, Integer_32);

      function Decode (Data : Byte_Array) return Unsigned_32 is
         (Shift_Left (Unsigned_32 (Data (Data'Last)), 24) +
          Shift_Left (Unsigned_32 (Data (Data'First + 1)), 16) +
          Shift_Left (Unsigned_32 (Data (Data'First)), 8));

      function Decode (Data : Byte_Array) return Integer_32 is
         (Cast (Shift_Right_Arithmetic (Decode (Data), 8)));

   begin
      return
        (X => Decode (Raw (16#11# .. 16#13#)),
         Y => Decode (Raw (16#14# .. 16#16#)),
         Z => Decode (Raw (16#17# .. 16#19#)));
   end Get_Raw_Measurement;

   ---------------------
   -- Get_Temperature --
   ---------------------

   function Get_Temperature (Raw : Byte_Array) return Deci_Celsius is
      use type Interfaces.Integer_16;

      function Cast is new Ada.Unchecked_Conversion
        (Byte, Interfaces.Integer_8);

      Result : constant Interfaces.Integer_16 :=
        (5100 - 100 * Interfaces.Integer_16 (Cast (Raw (16#1A#)))) / 17;
   begin
      return Deci_Celsius (Result);
   end Get_Temperature;

   -----------------------
   -- Set_Configuration --
   -----------------------

   function Set_Configuration
     (Value : Sensor_Configuration) return Configuration_Data
   is
      type Control_Register_1 is record
         WM       : Natural range 0 .. 7;
         Zero     : Natural range 0 .. 0 := 0;
         DTSET    : Boolean;
         RSV28    : Boolean := False;
         MT2      : Boolean;
      end record;

      for Control_Register_1 use record
         WM       at 0 range 0 .. 2;
         Zero     at 0 range 3 .. 4;
         DTSET    at 0 range 5 .. 5;
         RSV28    at 0 range 6 .. 6;
         MT2      at 0 range 7 .. 7;
      end record;

      function Cast_1 is new Ada.Unchecked_Conversion
        (Control_Register_1, Interfaces.Unsigned_8);

      type Control_Register_3 is record
         MODE     : Natural range 0 .. 16;
         MT       : Natural range 0 .. 3;
         FIFO     : Boolean;
      end record;

      for Control_Register_3 use record
         MODE     at 0 range 0 .. 4;
         MT       at 0 range 5 .. 6;
         FIFO     at 0 range 7 .. 7;
      end record;

      function Cast_3 is new Ada.Unchecked_Conversion
        (Control_Register_3, Interfaces.Unsigned_8);

      Mode : constant Natural :=
        (case Value.Mode is
            when Power_Down => 0,
            when Single_Measurement => 1,
            when Continuous_Measurement =>
              (case Value.Frequency is
                  when 10 => 2,
                  when 20 => 4,
                  when 50  => 6,
                  when 100 => 8,
                  when 200 => 10,
                  when 400 => 12,
                  when 1000 => 14,
                  when 2500 => 15),
            when Self_Test => 16,
            when External_Trigger => 24);

      MT   : constant Natural :=
        Natural'Max (0, Sensor_Drive'Pos (Value.Drive) - 1);

      WM : constant Natural := Positive (Value.Watermark) - 1;
      DTSET : constant Boolean := Value.Trigger_Pin;
      MT2 : constant Boolean := Value.Drive = Ultra_Low_Power_Drive;

      Data_30 : constant Interfaces.Unsigned_8 :=
        Cast_1 ((WM => WM, DTSET => DTSET, MT2 => MT2, others => <>));
      Data_31 : constant Interfaces.Unsigned_8 := 2#0100_0000#;
      Data_32 : constant Interfaces.Unsigned_8 :=
        Cast_3 ((MODE => Mode, MT => MT, FIFO => Value.Use_FIFO));
   begin
      return (Data_30, Data_31, Data_32);
   end Set_Configuration;

end AK09940A.Raw;
