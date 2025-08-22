--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package provides a low-level interface for interacting with the
--  sensor. Communication with the sensor is done by reading/writing one
--  or more bytes to predefined registers. The interface allows the user to
--  implement the read/write operations in the way they prefer but handles
--  encoding/decoding register values into user-friendly formats.
--
--  For each request to the sensor, the interface defines a subtype-array
--  where the index of the array element represents the register number to
--  read/write, and the value of the element represents the corresponding
--  register value.
--
--  Functions starting with `Set_` prepare values to be written to the
--  registers. Conversely, functions starting with `Get_` decode register
--  values. Functions starting with `Is_` are a special case for boolean
--  values.
--
--  The user is responsible for reading and writing register values!

package AK09940A.Raw is

   use type Byte;

   subtype Chip_Id_Data is Byte_Array (16#01# .. 16#01#);
   --  WIA: Who I Am. Company ID of AKM. Device ID of AK09940A.

   function Get_Chip_Id (Raw : Byte_Array) return Byte is
     (Raw (Chip_Id_Data'Last))
       with Pre => Chip_Id_Data'Last in Raw'Range;
   --  Read the chip ID. Raw data should contain Chip_Id_Data'Last item.

   subtype Control_1_Data is Byte_Array (16#30# .. 16#30#);
   --  CNTL1: Control 1

   function Set_Control_1 (Value : Sensor_Configuration) return Control_1_Data;
   --  Write CNTL1 Register. This includes watermark level, trigger pin, Ultra
   --  low power drive

   --  CNTL2: Control 2 is not very interesting, has temperature sensor switch

   subtype Control_3_Data is Byte_Array (16#32# .. 16#32#);
   --  CNTL3: Control 3

   function Set_Control_3 (Value : Sensor_Configuration) return Control_3_Data;
   --  Write CNTL3 Register. This includes mode, sensor drive, FIFO switch

   Reset_Data : constant Byte_Array (16#33# .. 16#33#) := (16#33# => 1);
   --  CNTL4: Control 4. SRST: Soft reset

   Disable_I2C_Data : constant Byte_Array (16#36# .. 16#36#) :=
     (16#36# => 2#0001_1011#);
   --  I2CDIS: I2C Disable. This register disables I2C bus interface.

   subtype Status_Data is Byte_Array (16#0F# .. 16#0F#);
   --  ST: Status (for Polling)

   function Is_Data_Ready (Raw : Byte_Array) return Boolean is
      ((Raw (Status_Data'First) and 1) /= 0)
        with Pre => Status_Data'First in Raw'Range;
   --  DRDY bit turns to “1” when data is ready in Single measurement mode,
   --  Continuous measurement mode 1, 2, 3, 4, 5, 6, 7, 8, External trigger
   --  measurement mode or Self-test mode. It returns to “0” when any one
   --  of ST2 register or measurement data register (HXL to TMPS) is read.

   function Is_Data_Overrun (Raw : Byte_Array) return Boolean is
      ((Raw (Status_Data'First) and 2) /= 0)
         with Pre => Status_Data'First in Raw'Range;
   --  DOR bit turns to “1” when data has been skipped in Continuous
   --  measurement mode 1, 2, 3, 4, 5, 6, 7, 8 or External trigger measurement
   --  mode. It returns to “0” when ST2 register is read.

   subtype Measurement_Data is Byte_Array (16#11# .. 16#1B#);

   function Get_Measurement (Raw : Byte_Array) return Magnetic_Field_Vector
     with Pre => Measurement_Data'First in Raw'Range
       and then 16#19# in Raw'Range;

   function Get_Raw_Measurement (Raw : Byte_Array) return Raw_Vector
     with Pre => Measurement_Data'First in Raw'Range
       and then 16#19# in Raw'Range;

   function Get_Temperature (Raw : Byte_Array) return Deci_Celsius
     with Pre => 16#1A# in Raw'Range;

   ----------------------------------
   -- SPI/I2C Write/Read functions --
   ----------------------------------

   function SPI_Write (X : Register_Address) return Byte is
     (Byte (X) and 16#7F#);
   --  For read operation on the SPI bus the register address is passed with
   --  the highest bit off (0).

   function SPI_Read (X : Register_Address) return Byte is
     (Byte (X) or 16#80#);
   --  For write operation on the SPI bus the register address is passed with
   --  the highest bit on (1).

   function SPI_Write (X : Byte_Array) return Byte_Array is
     ((X'First - 1 => SPI_Write (X'First)) & X)
       with Pre => X'Length = 1;
   --  Prefix the byte array with the register address for the SPI write
   --  operation. The chip is able to write a single register in one go.

   function SPI_Read (X : Byte_Array) return Byte_Array is
     ((X'First - 1 => SPI_Read (X'First)) & X);
   --  Prefix the byte array with the register address for the SPI read
   --  operation

   function I2C_Write (X : Byte_Array) return Byte_Array is
     ((X'First - 1 => Byte (X'First)) & X)
       with Pre => X'Length = 1;
   --  Prefix the byte array with the register address for the I2C write
   --  operation

   function I2C_Read (X : Byte_Array) return Byte_Array renames I2C_Write;
   --  Prefix the byte array with the register address for the I2C read
   --  operation

end AK09940A.Raw;
