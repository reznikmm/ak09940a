--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with AK09940A.Internal;

package body AK09940A.SPI_Sensors is

   procedure Read
     (Self    : AK09940A_Sensor'Class;
      Data    : out Byte_Array;
      Success : out Boolean);

   procedure Write
     (Self    : AK09940A_Sensor'Class;
      Address : Register_Address;
      Data    : Interfaces.Unsigned_8;
      Success : out Boolean);

   package Sensor is new Internal (AK09940A_Sensor'Class, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id (Self : AK09940A_Sensor) return Boolean is
     (Sensor.Check_Chip_Id (Self, AK09940A_Chip_Id));

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Self    : AK09940A_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Sensor.Configure (Self, Value, Success);
   end Configure;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self    : AK09940A_Sensor'Class;
      Success : out Boolean) is
   begin
      Sensor.Disable_I2C (Self, Success);
   end Initialize;

   -------------------
   -- Is_Data_Ready --
   -------------------

   function Is_Data_Ready (Self : AK09940A_Sensor) return Boolean is
      (Sensor.Is_Data_Ready (Self));

   ----------
   -- Read --
   ----------

   procedure Read
     (Self    : AK09940A_Sensor'Class;
      Data    : out Byte_Array;
      Success : out Boolean)
   is
      use type HAL.UInt8;
      use all type HAL.SPI.SPI_Status;

      Addr   : constant HAL.UInt8 := HAL.UInt8 (Data'First) or 16#80#;
      Status : HAL.SPI.SPI_Status;
      Output : HAL.SPI.SPI_Data_8b (Data'Range);
   begin
      Self.SPI_CS.Clear;

      Self.SPI_Port.Transmit (HAL.SPI.SPI_Data_8b'(1 => Addr), Status);

      if Status = Ok then
         Self.SPI_Port.Receive (Output, Status);
         Data := [for J of Output => Interfaces.Unsigned_8 (J)];
      end if;

      Self.SPI_CS.Set;

      Success := Status = Ok;
   end Read;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Self    : AK09940A_Sensor;
      Value   : out Magnetic_Field_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement (Self, Value, Success);
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   procedure Read_Raw_Measurement
     (Self    : AK09940A_Sensor;
      Value   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Raw_Measurement (Self, Value, Success);
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Self    : AK09940A_Sensor;
      Success : out Boolean) is
   begin
      Sensor.Reset (Self, Success);
   end Reset;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self    : AK09940A_Sensor'Class;
      Address : Register_Address;
      Data    : Interfaces.Unsigned_8;
      Success : out Boolean)
   is
      use all type HAL.SPI.SPI_Status;

      Addr : constant HAL.UInt8 := HAL.UInt8 (Address);
      Status : HAL.SPI.SPI_Status;
   begin
      Self.SPI_CS.Clear;

      Self.SPI_Port.Transmit
        (HAL.SPI.SPI_Data_8b'[Addr, HAL.UInt8 (Data)],
         Status);

      Self.SPI_CS.Set;

      Success := Status = Ok;
   end Write;

end AK09940A.SPI_Sensors;
