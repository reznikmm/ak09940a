--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Interfaces;

package AK09940 is
   pragma Preelaborate;
   pragma Discard_Names;

   type Operating_Mode is
     (Power_Down,
      Single_Measurement,
      Continuous_Measurement,
      Self_Test);
   --  The Operating Mode

   type Sensor_Drive is
     (Low_Power_Drive_1,
      Low_Power_Drive_2,
      Low_Noise_Drive_1,
      Low_Noise_Drive_2);

   type Measurement_Frequency is range 10 .. 400
     with Static_Predicate =>
       Measurement_Frequency in 10 | 20 | 50 | 100 | 200 | 400;

   type Sensor_Configuration (Mode : Operating_Mode := Power_Down) is record
      Drive    : Sensor_Drive := Low_Noise_Drive_1;
      Use_FIFO : Boolean := False;

      case Mode is
         when Continuous_Measurement =>
            Frequency : Measurement_Frequency := 10;

         when others =>
            null;
      end case;
   end record
     with Dynamic_Predicate =>
       (if Sensor_Configuration.Mode = Continuous_Measurement
          and then Sensor_Configuration.Frequency = 400
        then Drive in Low_Power_Drive_1 .. Low_Power_Drive_2
        else True);

   type Watermark_Level is range 1 .. 8;
   --  FIFO Watermark level

   type Magnetic_Field is delta 1.0 / 2.0 ** 14 range -12.0 .. 12.0;
   --  Magnetic flux density in Gauss

   type Magnetic_Field_Vector is record
      X, Y, Z : Magnetic_Field;
   end record;

   use type Interfaces.Integer_32;

   subtype Raw_Magnetic_Field is Interfaces.Integer_32 range -2**17 .. 2**17;

   type Raw_Vector is record
      X, Y, Z : Raw_Magnetic_Field;
   end record;
   --  A value read from the sensor in raw format. The output data of each
   --  channel saturates at -131072 and 131071.

   subtype I2C_Address_Range is Interfaces.Unsigned_8 range 16#0C# .. 16#0F#;

private
   subtype Register_Address is Natural range 16#00# .. 16#7F#;
   --  Sensor registers addresses

   type Byte_Array is
     array (Register_Address range <>) of Interfaces.Unsigned_8;

end AK09940;
