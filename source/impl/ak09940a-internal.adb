--  SPDX-FileCopyrightText: 2024-20225 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with AK09940A.Raw;

package body AK09940A.Internal is

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id
     (Device : Device_Context;
      Expect : Interfaces.Unsigned_8) return Boolean
   is
      Ok   : Boolean;
      Data : Byte_Array (0 .. 1);
   begin
      Read (Device, Data, Ok);

      return Ok and Data = (16#48#, Expect);
   end Check_Chip_Id;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Device  : Device_Context;
      Value   : Sensor_Configuration;
      Success : out Boolean)
   is
      Control_1 : constant Raw.Control_1_Data := Raw.Set_Control_1 (Value);
      Control_3 : constant Raw.Control_3_Data := Raw.Set_Control_3 (Value);
   begin
      Write (Device, Control_1'First, Control_1 (Control_1'First), Success);

      if Success then
         Write (Device, Control_3'Last, Control_3 (Control_3'Last), Success);
      end if;
   end Configure;

   -----------------
   -- Disable_I2C --
   -----------------

   procedure Disable_I2C
     (Device  : Device_Context;
      Success : out Boolean)
   is
      Data : Byte_Array renames Raw.Disable_I2C_Data;
   begin
      Write (Device, Data'First, Data (Data'First), Success);
   end Disable_I2C;

   -------------------
   -- Is_Data_Ready --
   -------------------

   function Is_Data_Ready (Device  : Device_Context) return Boolean is
      Ok   : Boolean;
      Data : Raw.Status_Data;  --  ST: Status (for Polling)
   begin
      Read (Device, Data, Ok);

      return Ok and Raw.Is_Data_Ready (Data);
   end Is_Data_Ready;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Device  : Device_Context;
      Value   : out Magnetic_Field_Vector;
      Success : out Boolean)
   is
      Data : Raw.Measurement_Data;
   begin
      Read (Device, Data, Success);

      if Success then
         Value := Raw.Get_Measurement (Data);
      else
         Value := (X | Y | Z => Magnetic_Field'First);
      end if;
   end Read_Measurement;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Raw_Measurement
     (Device  : Device_Context;
      Value   : out Raw_Vector;
      Success : out Boolean)
   is
      Data : Raw.Measurement_Data;
   begin
      Read (Device, Data, Success);

      if Success then
         Value := Raw.Get_Raw_Measurement (Data);
      else
         Value := (X | Y | Z => Raw_Magnetic_Field'First);
      end if;
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Device  : Device_Context;
      Success : out Boolean)
   is
      Data : Byte_Array renames Raw.Reset_Data;
   begin
      Write (Device, Data'First, Data (Data'First), Success);
   end Reset;

end AK09940A.Internal;
