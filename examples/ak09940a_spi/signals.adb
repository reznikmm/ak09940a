--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with STM32.Device;
with STM32.EXTI;

package body Signals is

   EXTI_Line : constant STM32.EXTI.External_Line_Number :=
     STM32.Device.PB6.Interrupt_Line_Number;

   protected body Magnetometer is

      entry Wait when Ready is
      begin
         Ready := False;
      end Wait;

      procedure Interrupt is
      begin
         STM32.EXTI.Clear_External_Interrupt (EXTI_Line);
         --  STM32.Device.PA7.Toggle;  toggle a led
         Ready := True;
      end Interrupt;

   end Magnetometer;


end Signals;
