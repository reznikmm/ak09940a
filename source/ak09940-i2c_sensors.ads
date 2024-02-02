--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package offers a straightforward method for setting up the AK09940
--  when connected via I2C, especially useful when you need multiple sensors
--  of this kind. If you use only one sensor, it could be preferable to use the
--  AK09940.I2C generic package.

with HAL.I2C;

package AK09940.I2C_Sensors is

   type AK09940_Sensor
     (I2C_Port    : not null HAL.I2C.Any_I2C_Port;
      I2C_Address : I2C_Address_Range) is tagged limited null record;

   function Check_Chip_Id
     (Self   : AK09940_Sensor;
      Expect : Interfaces.Unsigned_8 := AK09940_Chip_Id) return Boolean;
   --  Read the chip ID and check that it matches the expected value.

   procedure Reset
     (Self    : AK09940_Sensor;
      Success : out Boolean);
   --  Soft reset, restore default value of all registers.

   procedure Configure
     (Self    : AK09940_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean);
   --  Setup sensor configuration, including
   --  * Operating mode
   --  * Measurement frequency
   --  * Sensor drive
   --  * FIFO activation

   procedure Set_FIFO_Water_Mark
     (Self    : AK09940_Sensor;
      Value   : Watermark_Level;
      Success : out Boolean);
   --  It is prohibited to change watermark in any other modes than Power_Down
   --  mode.

   procedure Enable_Temperature
     (Self    : AK09940_Sensor;
      Value   : Boolean;
      Success : out Boolean);
   --  Enable temperature measurement (On by default).

   function Is_Data_Ready (Self : AK09940_Sensor) return Boolean;
   --  Return True when data is ready (if FIFO disabled) or the number of
   --  records stored is equal to or greater than the watermark (if FIFO
   --  enabled).

   procedure Read_Measurement
     (Self    : AK09940_Sensor;
      Value   : out Magnetic_Field_Vector;
      Success : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Self    : AK09940_Sensor;
      Value   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

end AK09940.I2C_Sensors;
