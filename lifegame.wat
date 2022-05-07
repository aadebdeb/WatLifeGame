(module
  (import "env" "memory" (memory 1))
  (global $width (import "env" "width") i32)
  (global $height (import "env" "height") i32)

  (func $load_state
    (param $x i32)
    (param $y i32)
    (param $offset i32)
    (result i32)

    (i32.load8_u
      (i32.add ;; $x + $y * $width + $offset
        (i32.add
          (local.get $x)
          (i32.mul (local.get $y) (global.get $width))
        )
        (local.get $offset)
      )
      
    )
  )

  (func $store_state
    (param $x i32)
    (param $y i32)
    (param $offset i32)
    (param $alive i32)

    (i32.store8
      (i32.add ;; $x + $y * $width + $offset
        (i32.add
          (local.get $x)
          (i32.mul (local.get $y) (global.get $width))
        )
        (local.get $offset)
      )
      (local.get $alive)
    )
  )

  (func
    (export "update")
    (param $src_address i32)
    (param $dst_address i32)

    (local $x i32)
    (local $y i32)
    (local $top i32)
    (local $bottom i32)
    (local $left i32)
    (local $right i32)
    (local $neighbors i32)
    (local $alive i32)

    (local.set $y (i32.const 0)) ;; $y = 0
    (loop $continue_y

      ;; $top = $y == $height - 1 ? 0 : $y + 1
      (if (i32.eq (local.get $y) (i32.sub (global.get $height) (i32.const 1)))
        (then
          (local.set $top (i32.const 0))
        )
        (else
          (local.set $top
            (i32.add (local.get $y) (i32.const 1))
          )
        )
      )

      ;; $bottom = $y == 0 ? $height - 1 : $y - 1
      (if (i32.eqz (local.get $y))
        (then
          (local.set $bottom
            (i32.sub (global.get $height) (i32.const 1))
          )
        )
        (else
          (local.set $bottom
            (i32.sub (local.get $y) (i32.const 1))
          )
        )
      )

      (local.set $x (i32.const 0)) ;; $x = 0
      (loop $continue_x

        ;; $right = $x == $width - 1 ? 0 : $x + 1
        (if (i32.eq (local.get $x) (i32.sub (global.get $width) (i32.const 1)))
          (then
            (local.set $right (i32.const 0))
          )
          (else
            (local.set $right
              (i32.add (local.get $x) (i32.const 1))
            )
          )
        )

        ;; $left = $x == 0 ? $width - 1 : $x - 1
        (if (i32.eqz (local.get $x))
          (then
            (local.set $left
              (i32.sub (global.get $width) (i32.const 1))
            )
          )
          (else
            (local.set $left
              (i32.sub (local.get $x) (i32.const 1))
            )
          )
        )

        (local.set $alive ;; $alive = current_state($x, $y)
          (call $load_state (local.get $x) (local.get $y) (local.get $src_address))
        )

        (local.set $neighbors (i32.const 0)) ;; $neighbors == 0
        (local.set $neighbors ;; $neighbors += current_state($left, $top)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $left) (local.get $top) (local.get $src_address))
          )
        )
        (local.set $neighbors ;; $neighbors += current_state($x, $top)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $x) (local.get $top) (local.get $src_address))
          )
        )
        (local.set $neighbors ;; $neighbors += current_state($right, $top)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $right) (local.get $top) (local.get $src_address))
          )
        )
        (local.set $neighbors ;; $neighbors += current_state($left, $y)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $left) (local.get $y) (local.get $src_address))
          )
        )
        (local.set $neighbors ;; $neighbors += current_state($right, $y)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $right) (local.get $y) (local.get $src_address))
          )
        )
        (local.set $neighbors ;; $neighbors += stcurrent_stateate($left, $bottom)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $left) (local.get $bottom) (local.get $src_address))
          )
        )
        (local.set $neighbors ;; $neighbors += current_state($x, $bottom)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $x) (local.get $bottom) (local.get $src_address))
          )
        )
        (local.set $neighbors ;; $neighbors += current_state($right, $bottom)
          (i32.add
            (local.get $neighbors)
            (call $load_state (local.get $right) (local.get $bottom) (local.get $src_address))
          )
        )

        (if
          (i32.or
            (i32.and ;; $alive == 1 && ($neighbors == 2 || $neighbors == 3)
              (i32.eq (local.get $alive) (i32.const 1))
              (i32.or
                (i32.eq (local.get $neighbors) (i32.const 2))
                (i32.eq (local.get $neighbors) (i32.const 3))
              )
            )
            (i32.and ;; $alive == 0 && $neighbors == 3
              (i32.eqz (local.get $alive))
              (i32.eq (local.get $neighbors) (i32.const 3))
            )
          )
          (then ;; next state is alive: next_state($x, $y) = 1
            (call $store_state (local.get $x) (local.get $y) (local.get $dst_address) (i32.const 1))
          )
          (else ;; next state is dead: next_state($x, $y) = 0
            (call $store_state (local.get $x) (local.get $y) (local.get $dst_address) (i32.const 0))
          )
        )

        (local.set $x (i32.add (local.get $x) (i32.const 1))) ;; $x++
        (br_if $continue_x (i32.lt_u (local.get $x) (global.get $width))) ;; continue if: $x < $width
      )

      (local.set $y (i32.add (local.get $y) (i32.const 1))) ;; $y++
      (br_if $continue_y (i32.lt_u (local.get $y) (global.get $height))) ;; continue if: $y < $height
    )
  )
)