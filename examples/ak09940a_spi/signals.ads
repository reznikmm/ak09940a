--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  The protected type for handling the interrupt wrapped in a package

with Ada.Interrupts.Names;

package Signals is

   protected Magnetometer is
      pragma Interrupt_Priority;

      entry Wait;

   private

      procedure Interrupt;

      pragma Attach_Handler
        (Interrupt, Ada.Interrupts.Names.EXTI9_5_Interrupt);

      Ready : Boolean := False;

   end Magnetometer;


end Signals;
