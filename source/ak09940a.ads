--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  Top level package for 3-axis magnetic sensor AK09940A

with Interfaces;

package AK09940A is
   pragma Preelaborate;
   pragma Discard_Names;

   type Operating_Mode is
     (Power_Down,
      Single_Measurement,
      Continuous_Measurement,
      External_Trigger,
      Self_Test);
   --  The Operating Mode.

   type Sensor_Drive is
     (Ultra_Low_Power_Drive,
      Low_Power_Drive_1,
      Low_Power_Drive_2,
      Low_Noise_Drive_1,
      Low_Noise_Drive_2);

   type Measurement_Frequency is range 10 .. 2_500
     with Static_Predicate => Measurement_Frequency in
       10 | 20 | 50 | 100 | 200 | 400 | 1_000 | 2_500;

   type Watermark_Level is range 1 .. 8;
   --  FIFO Watermark level

   type Sensor_Configuration (Mode : Operating_Mode := Power_Down) is record
      --  After Power_Down mode is set, at least 100 µs is needed before
      --  setting another mode.

      Drive : Sensor_Drive := Low_Noise_Drive_1;
      --  Drive can be changed in Power_Down mode only.

      Use_FIFO : Boolean := False;
      Watermark : Watermark_Level := 1;
      Trigger_Pin : Boolean := False;
      --  When True: DRDY pin turns to TRG pin.

      case Mode is
         when Continuous_Measurement =>
            Frequency : Measurement_Frequency := 10;

         when others =>
            null;
      end case;
   end record
     with Dynamic_Predicate =>
       (if Sensor_Configuration.Mode = External_Trigger then
          Sensor_Configuration.Trigger_Pin
        elsif Sensor_Configuration.Mode = Continuous_Measurement then
        (case Sensor_Configuration.Frequency is
           when 400   => Drive in Ultra_Low_Power_Drive .. Low_Power_Drive_2,
           when 1_000 => Drive in Ultra_Low_Power_Drive .. Low_Power_Drive_1,
           when 2_500 => Drive in Ultra_Low_Power_Drive,
           when others => True)
        else True);

   type Magnetic_Field is delta 1.0 / 2.0 ** 14 range -14.0 .. 14.0;
   --  Magnetic flux density in Gauss

   type Magnetic_Field_Vector is record
      X, Y, Z : Magnetic_Field;
   end record;

   type Deci_Celsius is range -44_7 .. 105_3;
   --  1 degree celsius is 10 Deci_Celsius

   use type Interfaces.Integer_32;

   subtype Raw_Magnetic_Field is Interfaces.Integer_32
     range -2 ** 17 .. 2 ** 17 - 1;

   type Raw_Vector is record
      X, Y, Z : Raw_Magnetic_Field;
   end record;
   --  A value read from the sensor in raw format. The output data of each
   --  channel saturates at -131072 and 131071.

   subtype I2C_Address_Range is Interfaces.Unsigned_8 range 16#0C# .. 16#0F#;

   AK09940A_Chip_Id : constant := 16#A3#;

   subtype Register_Address is Natural range 16#00# .. 16#FF#;
   --  Sensor registers addresses

   subtype Byte is Interfaces.Unsigned_8;  --  Register value

   type Byte_Array is array (Register_Address range <>) of Byte;

end AK09940A;
