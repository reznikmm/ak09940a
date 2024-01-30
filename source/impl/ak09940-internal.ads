--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

private generic
   type Device_Context (<>) is limited private;

   with procedure Read
     (Device  : Device_Context;
      Data    : out Byte_Array;
      Success : out Boolean);
   --  Read the values from the AK09940 chip registers into Data.
   --  Each element in the Data corresponds to a specific register address
   --  in the chip, so Data'Range determines the range of registers to read.
   --  The value read from register X will be stored in Data(X), so
   --  Data'Range should be of the Register_Address subtype.

   with procedure Write
     (Device  : Device_Context;
      Address : Register_Address;
      Data    : Interfaces.Unsigned_8;
      Success : out Boolean);
   --  Write the Data values to the AK09940 chip registers.
   --  Each element in the Data corresponds to a specific register address
   --  in the chip, so Data'Range determines the range of registers to write.
   --  The value read from Data(X) will be stored in register X, so
   --  Data'Range should be of the Register_Address subtype.

package AK09940.Internal is

   function Check_Chip_Id (Device : Device_Context) return Boolean;
   --  Read the chip ID and check that it matches

   procedure Configure
     (Device  : Device_Context;
      Value   : Sensor_Configuration;
      Success : out Boolean);
   --  Write CNTL3 Register (32)

   procedure Reset
     (Device  : Device_Context;
      Success : out Boolean);
   --  Write CNTL4 Register (33)

   procedure Set_FIFO_Water_Mark
     (Device  : Device_Context;
      Value   : Watermark_Level;
      Success : out Boolean);
   --  Write CNTL1 Register (30).
   --  It is prohibited to change watermark in any other modes than Power-down
   --  mode.

   procedure Enable_Temperature
     (Device  : Device_Context;
      Value   : Boolean;
      Success : out Boolean);
   --  Write CNTL2 Register (31).

   procedure Disable_I2C
     (Device  : Device_Context;
      Success : out Boolean);
   --  Write I2CDIS Register (36)

   function Is_Data_Ready (Device  : Device_Context) return Boolean;
   --  Check if the operating mode is idle

   procedure Read_Measurement
     (Device     : Device_Context;
      Value      : out Magnetic_Field_Vector;
      Success    : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Device  : Device_Context;
      Value   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

end AK09940.Internal;
