--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with AK09940.Internal;

package body AK09940.I2C is

   type Chip_Settings is null record;

   Chip : Chip_Settings;

   procedure Read
     (Ignore  : Chip_Settings;
      Data    : out Byte_Array;
      Success : out Boolean);
   --  Read registers starting from Data'First

   procedure Write
     (Ignore  : Chip_Settings;
      Address : Register_Address;
      Data    : Interfaces.Unsigned_8;
      Success : out Boolean);
   --  Write a register (at Address) with Data

   package Sensor is new Internal (Chip_Settings, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id
     (Expect : Interfaces.Unsigned_8 := AK09940_Chip_Id) return Boolean is
       (Sensor.Check_Chip_Id (Chip, Expect));

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Sensor.Configure (Chip, Value, Success);
   end Configure;

   ------------------------
   -- Enable_Temperature --
   ------------------------

   procedure Enable_Temperature
     (Value   : Boolean;
      Success : out Boolean) is
   begin
      Sensor.Enable_Temperature (Chip, Value, Success);
   end Enable_Temperature;

   -------------------
   -- Is_Data_Ready --
   -------------------

   function Is_Data_Ready return Boolean is (Sensor.Is_Data_Ready (Chip));

   ----------
   -- Read --
   ----------

   procedure Read
     (Ignore  : Chip_Settings;
      Data    : out Byte_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Output : HAL.I2C.I2C_Data (Data'Range);
      Status : HAL.I2C.I2C_Status;
   begin
      I2C_Port.Mem_Read
        (Addr          => 2 * HAL.UInt10 (I2C_Address),
         Mem_Addr      => HAL.UInt16 (Data'First),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => Output,
         Status        => Status);

      Data := [for J of Output => Interfaces.Unsigned_8 (J)];

      Success := Status = HAL.I2C.Ok;
   end Read;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Value   : out Magnetic_Field_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement (Chip, Value, Success);
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   procedure Read_Raw_Measurement
     (Value   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Raw_Measurement (Chip, Value, Success);
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset (Success : out Boolean) is
   begin
      Sensor.Reset (Chip, Success);
   end Reset;

   -------------------------
   -- Set_FIFO_Water_Mark --
   -------------------------

   procedure Set_FIFO_Water_Mark
     (Value   : Watermark_Level;
      Success : out Boolean) is
   begin
      Sensor.Set_FIFO_Water_Mark (Chip, Value, Success);
   end Set_FIFO_Water_Mark;

   -----------
   -- Write --
   -----------

   procedure Write
     (Ignore  : Chip_Settings;
      Address : Register_Address;
      Data    : Interfaces.Unsigned_8;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      I2C_Port.Mem_Write
        (Addr          => 2 * HAL.UInt10 (I2C_Address),
         Mem_Addr      => HAL.UInt16 (Address),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => [HAL.UInt8 (Data)],
         Status        => Status);

      Success := Status = HAL.I2C.Ok;
   end Write;

end AK09940.I2C;
