--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with AK09940.Internal;

package body AK09940.I2C_Sensors is

   procedure Read
     (Self    : AK09940_Sensor'Class;
      Data    : out Byte_Array;
      Success : out Boolean);

   procedure Write
     (Self    : AK09940_Sensor'Class;
      Address : Register_Address;
      Data    : Interfaces.Unsigned_8;
      Success : out Boolean);

   package Sensor is new Internal (AK09940_Sensor'Class, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id (Self : AK09940_Sensor) return Boolean is
      (Sensor.Check_Chip_Id (Self));

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Self    : AK09940_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Sensor.Configure (Self, Value, Success);
   end Configure;

   ------------------------
   -- Enable_Temperature --
   ------------------------

   procedure Enable_Temperature
     (Self    : AK09940_Sensor;
      Value   : Boolean;
      Success : out Boolean) is
   begin
      Sensor.Enable_Temperature (Self, Value, Success);
   end Enable_Temperature;

   -------------------
   -- Is_Data_Ready --
   -------------------

   function Is_Data_Ready (Self : AK09940_Sensor) return Boolean is
      (Sensor.Is_Data_Ready (Self));

   ----------
   -- Read --
   ----------

   procedure Read
     (Self    : AK09940_Sensor'Class;
      Data    : out Byte_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
      Output : HAL.I2C.I2C_Data (Data'Range);
   begin
      Self.I2C_Port.Mem_Read
        (Addr          => 2 * HAL.UInt10 (Self.I2C_Address),
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
     (Self    : AK09940_Sensor;
      Value   : out Magnetic_Field_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement (Self, Value, Success);
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   procedure Read_Raw_Measurement
     (Self    : AK09940_Sensor;
      Value   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Raw_Measurement (Self, Value, Success);
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Self    : AK09940_Sensor;
      Success : out Boolean) is
   begin
      Sensor.Reset (Self, Success);
   end Reset;

   -------------------------
   -- Set_FIFO_Water_Mark --
   -------------------------

   procedure Set_FIFO_Water_Mark
     (Self    : AK09940_Sensor;
      Value   : Watermark_Level;
      Success : out Boolean) is
   begin
      Sensor.Set_FIFO_Water_Mark (Self, Value, Success);
   end Set_FIFO_Water_Mark;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self    : AK09940_Sensor'Class;
      Address : Register_Address;
      Data    : Interfaces.Unsigned_8;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      Self.I2C_Port.Mem_Write
        (Addr          => 2 * HAL.UInt10 (Self.I2C_Address),
         Mem_Addr      => HAL.UInt16 (Address),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => [HAL.UInt8 (Data)],
         Status        => Status);

      Success := Status = HAL.I2C.Ok;
   end Write;

end AK09940.I2C_Sensors;
