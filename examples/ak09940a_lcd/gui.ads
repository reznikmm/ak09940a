--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with GUI_Buttons;
with HAL.Bitmap;
with HAL.Touch_Panel;

package GUI is

   type Button_Kind is
     (Fx, Fy, Fz,       --  Field components
      UL, P1, P2, N1, N2,   --  Driver
      SM,  --  Single_Measurement
      ST,  --  Self_Test
      F10, F20, F50, F100, F200, F400, F1000, F2500);  --  Freq

   function "+" (X : Button_Kind) return Natural is (Button_Kind'Pos (X))
     with Static;

   Buttons : constant GUI_Buttons.Button_Info_Array :=
     [(Label  => "Fx",
       Center => (23 * 1, 20),
       Color  => HAL.Bitmap.Red),
      (Label  => "Fy",
       Center => (23 * 2, 20),
       Color  => HAL.Bitmap.Green),
      (Label  => "Fz",
       Center => (23 * 3, 20),
       Color  => HAL.Bitmap.Blue),
      (Label  => "UL",
       Center => (23 * 1 + 160, 20),
       Color  => HAL.Bitmap.Yellow),
      (Label  => "P1",
       Center => (23 * 2 + 160, 20),
       Color  => HAL.Bitmap.Yellow),
      (Label  => "P2",
       Center => (23 * 3 + 160, 20),
       Color  => HAL.Bitmap.Yellow),
      (Label  => "N1",
       Center => (23 * 4 + 160, 20),
       Color  => HAL.Bitmap.Yellow),
      (Label  => "N2",
       Center => (23 * 5 + 160, 20),
       Color  => HAL.Bitmap.Yellow),
      (Label  => "SM",
       Center => (23 * 1, 220),
       Color  => HAL.Bitmap.Dark_Green),
      (Label  => "ST",
       Center => (23 * 2, 220),
       Color  => HAL.Bitmap.Dark_Green),
      (Label  => "10",
       Center => (23 * 1 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "20",
       Center => (23 * 2 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "50",
       Center => (23 * 3 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "1H",
       Center => (23 * 4 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "2H",
       Center => (23 * 5 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "4H",
       Center => (23 * 6 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "1T",
       Center => (23 * 7 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "2T",
       Center => (23 * 8 + 110, 220),
       Color  => HAL.Bitmap.Dim_Grey)];

   State : GUI_Buttons.Boolean_Array (Buttons'Range) :=
     [+Fx | +Fy | +Fz | +UL | +F10 => True, others => False];

   procedure Check_Touch
     (TP     : in out HAL.Touch_Panel.Touch_Panel_Device'Class;
      Update : out Boolean);
   --  Check buttons touched, update State, set Update = True if State changed

   procedure Draw
     (LCD   : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Clear : Boolean := False);

   procedure Dump_Screen (LCD : in out HAL.Bitmap.Bitmap_Buffer'Class);

end GUI;
