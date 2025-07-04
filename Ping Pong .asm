[org 0x100]
jmp start
	;=================Data Section===================
;--------------------- Welcome messages ------------------------
msg0 db '--------------------------------',0
msg1 db 'WELCOME TO PING PONG!', 0
msg2 db 'Faryal jafferi BCS (23F-0606)', 0
msg3 db 'Rida Mehmood BCS (23F-0554)', 0
msg4 db '--------------------------------',0
menu0 db 'INSTRUCTIONS:',0
menu1 db 'Player 1: Press W to move up, S to move down.', 0
menu2 db 'Player 2: Press ArrowUp and ArrowDown keys for movement.', 0
menu3 db 'When the Ball is missed from the Opponent Player your score Increase!', 0

;---------------------- Winning messages-------------------------
msg_player1_wins db 'PLAYER 1 WINS!', 0
msg_player2_wins db 'PLAYER 2 WINS!', 0
msg_restart db 'Press R to restart or E to exit.', 0

;------------------ Data for ball position and direction-----------------
ball_pos_x dw 40           ; Initial X position of the ball 
ball_pos_y dw 12           ; Initial Y position of the ball
ball_vel_x dw 0            ; Horizontal velocity of the ball
ball_vel_y dw 0            ; Vertical velocity of the ball
ball_dir dw 164            ; Initial direction
speed_counter dw 100       ; ball speed 

;------------------------ Data for paddles positions------------------------
player1_y_position dw 320                     ; Initial position of player 1
player2_y_position dw 318                      ; Initial position of player 2 

;---------------------------- Score variables--------------------------------
player1_score db 0          ; Score for Player 1
player2_score db 0          ; Score for Player 2
winning_score db 5          ; Score needed to win

;----------------------- paused state Variable ------------------------
paused db 0                ; 0 = game is running, 1 = game is paused

;------------------------ Background patterns ------------------------------
patterns db '~','.','-','*',0       ; Background patterns
current_pattern db 0                ; Index of the current pattern

;==================Printing Message==================
print_msg:
    mov ax, 0xb800      
    mov es, ax
    mov si, bx          ; Load address of msg from BX
next_char:
    lodsb               ; Load next character from the message
    cmp al, 0           ; Check if end of string
    je done
    mov ah, 0x02       
    mov [es:di], ax    
    add di, 2           ; Move to the next character position
    jmp next_char
done:
    ret

;================ Interrupt for enter label ====================
wait_to_press:
    mov ah, 0           ; BIOS keyboard interrupt function
    int 16h             ; Wait for key press
    cmp al, 0x0D        ; Check if Enter key 
    jne wait_to_press   
    ret

;=================== Clear screen ==============================
clear_screen:
    mov ax, 0xb800        
    mov es, ax
    mov di, 0              ; Start from 0th row
clear_loop:
    mov word [es:di], 0x0720 ; Print Blank space
    add di, 2              ; Move to the next character position
    cmp di, 4000           ; Check if end of the screen
    jne clear_loop
    ret
	
;==================== Draw Backgroundm=========================
change_background:
    mov al, [current_pattern]      ; Load the current pattern index
    inc al                         ; Increment the index
    cmp al, 4                      ; Check if last pattern
    jle set_background
    xor al, al                     ; Reset to the first pattern if end
set_background:
    mov [current_pattern], al      ; Update the current pattern index
    call draw_background           ; Draw the new background
    ret
	draw_background:
    mov ax, 0xb800             
    mov es, ax
    mov di, 0                     ; Start from 0th row
    mov cx, 2000               

    mov al, [current_pattern]     ; Load index of the current pattern
    and al, 3                     ; Mask with 3 (binary 00000011) to keep the index within 0-3
    mov bx, patterns              ; Load base address
    add bx, ax                    ; Calculate address of current pattern
    mov al, [bx]                  ; Fetch the pattern character
    mov ah, 0x07                  ; White text on black background

draw_background_loop:
    mov word[es:di], ax      
    add di, 6                     ; Move to the next character position
    loop draw_background_loop
    ret

;======================= Draw top and bottom walls ==========================
draw_wall:
    mov ax, 0xb800
    mov es, ax
    mov di, 160                  ;wall position for top
    mov cx, 80                   ; counter to display 80 scharacters per row
top_border:
    mov word [es:di], 0x052A     ;display pink asterick
    add di, 2                    ; next character location
    loop top_border
    mov di, 3680                 ; wall position for bottom
    mov cx, 80                   ; counter to display 80 scharacters per row
bottom_border:
    mov word [es:di], 0x052A     ;display pink asterick
    add di, 2                    ; next character location
    loop bottom_border
    ret

;===================== Set initial velocity based on direction =====================
set_initial_velocity:
    mov ax, [ball_dir]
    cmp ax, 164            ; Top-right
    je dir_top_right
    cmp ax, -164           ; Top-left
    je dir_top_left
    cmp ax, 156            ; Bottom-right
    je dir_bottom_right
    cmp ax, -156           ; Bottom-left
    je dir_bottom_left

dir_top_right:
    mov word [ball_vel_x], 1
    mov word [ball_vel_y], -1
    ret

dir_top_left:
    mov word [ball_vel_x], -1
    mov word [ball_vel_y], -1
    ret

dir_bottom_right:
    mov word [ball_vel_x], 1
    mov word [ball_vel_y], 1
    ret

dir_bottom_left:
    mov word [ball_vel_x], -1
    mov word [ball_vel_y], 1
    ret

;====================== Move and redraw the ball =============================
move_ball:
    push ax
    push bx
    push cx
    push dx

    mov ax, [speed_counter]
    cmp ax, 0              ; If counter is 0, move the ball
    je move_ball_logic

    ; If counter is not 0, just return and don't move the ball
    dec word [speed_counter] ; Decrease the counter
    pop dx
    pop cx
    pop bx
    pop ax
    ret

move_ball_logic:
    ; Clear current ball position
    mov ax, 0xb800
    mov es, ax
    mov bl, 80
    mov ax, [ball_pos_y]
    mul bl
    add ax, [ball_pos_x]
    shl ax, 1
    mov di, ax
    mov ax, 0x0720         ; Restore blank space
    stosw

    ; Update ball position
    mov ax, [ball_pos_x]
    add ax, [ball_vel_x]   ; Update horizontal position
    mov [ball_pos_x], ax

    mov ax, [ball_pos_y]
    add ax, [ball_vel_y]   ; Update vertical position
    mov [ball_pos_y], ax

    ; Check collisions and reverse direction if needed
    call check_collisions

    ; Draw ball at new position
    mov ax, 0xb800
    mov es, ax
    mov bl, 80
    mov ax, [ball_pos_y]
    mul bl
    add ax, [ball_pos_x]
    shl ax, 1
    mov di, ax
    mov ax, 0x044F          ; Ball (character 'O')
    stosw

    mov word [speed_counter], 1500         ; Increase the speed counter for slower movement

    pop dx
    pop cx
    pop bx
    pop ax
    ret
;===========================Check collision with boundary=============================
check_collisions:
    cmp word [ball_pos_x], 2      ; Check left boundary
    jge check_right               ; If ball is not at left boundary, check right

    ; Reverse horizontal direction
    mov word [ball_vel_x], 1
    ; Adjust direction for left reflection
    add word [ball_dir], 8

    ; Check if ball is within paddle range (Player 1 paddle is 3 lines)
    mov dx, [ball_pos_y]          ; Load ball's Y position
    mov ax, [player1_y_position]  ; Load paddle's Y top position
    cmp dx, ax                    ; Check if ball == top position
    je check_y
    add ax,160                       ; Move to next paddle line
    cmp dx, ax                    ; Check if ball == middle position
    je check_y
    add ax,160                       ; Move to next paddle line
    cmp dx, ax                    ; Check if ball == bottom position
    je check_y

    ; If ball missed the paddle, increment Player 2's score
    inc byte [player2_score]
    jmp check_y

check_right:
    cmp word [ball_pos_x], 78     ; Check right boundary
    jle check_y                   ; If ball is not at right boundary, check Y collisions

    ; Reverse horizontal direction
    mov word [ball_vel_x], -1
    ; Adjust direction for right reflection
    sub word [ball_dir], 8

    ; Check if ball is within paddle range (Player 2 paddle is 3 lines)
    mov dx, [ball_pos_y]          ; Load ball's Y position
    mov ax, [player2_y_position]  ; Load paddle's Y top position
    cmp dx, ax                    ; Check if ball == top position
    je check_y
    add ax,160                       ; Move to next paddle line
    cmp dx, ax                    ; Check if ball == middle position
    je check_y
   add ax,160                        ; Move to next paddle line
    cmp dx, ax                    ; Check if ball == bottom position
    je check_y

    ; If ball missed the paddle, increment Player 1's score
    inc byte [player1_score]


check_y:
    cmp word [ball_pos_y], 1  ; Check top boundary
    jge check_bottom
    ; Reverse vertical direction
    mov word [ball_vel_y], 1
    ; Adjust direction for top reflection
    add word [ball_dir], 320
    jmp finish_collision

check_bottom:
    cmp word [ball_pos_y], 23 ; Check bottom boundary
    jle finish_collision
    ; Reverse vertical direction
    mov word [ball_vel_y], -1
    ; Adjust direction for bottom reflection
    sub word [ball_dir], 320

finish_collision:
    ret
	
;=================================== Draw paddles ================================
draw_paddles_on_screen:
    mov ax, 0xb800                                 
    mov es, ax
    mov cx, 3                                     ; Paddle height 
    mov di, [player1_y_position]                  ; Starting position of Player 1's paddle
draw_player1_paddle:
    mov word [es:di], 0x0A7C                      ; Draw '|' character in green
    add di, 160                                   ; Move to the next row 
    loop draw_player1_paddle
    mov cx, 3                                     ; Paddle height 
    mov di, [player2_y_position]                  ; Starting position of Player 2's paddle
draw_player2_paddle:
    mov word [es:di], 0xB7C                       ; Draw '|' character in skyblue
    add di, 160                                   ; Move to the next row
    loop draw_player2_paddle
    ret

;=========================== Clear paddles area===================================
clear_paddles_area:
    mov ax, 0xb800        
    mov es, ax
    ; Clear Player 1's paddle area 
    mov cx, 3
    mov di, [player1_y_position]
clear_player1_paddle_area:
    mov word [es:di], 0x0720                                ; Print space 
    add di, 160
    loop clear_player1_paddle_area
    mov cx, 3
    mov di, [player2_y_position]
clear_player2_paddle_area:
    mov word [es:di], 0x0720                                ; Print space
    add di, 160
    loop clear_player2_paddle_area
    ret

;================= Handle input from Keyboard ==================================
handle_input:
    mov ah, 0x01                ; Check if a key is pressed
    int 0x16
    jz no_key_pressed           ; Skip if no key is pressed
    mov ah, 0x00                ; Get the key
    int 0x16
    cmp al, 'w'                 ; Player 1: Move up
    je move_player1_up
    cmp al, 's'                 ; Player 1: Move down
    je move_player1_down
    cmp ah, 0x48                ; Player 2: Move up
    je move_player2_up
    cmp ah, 0x50                ; Player 2: Move down
    je move_player2_down
    cmp al, 'b'                 ; Check for background 
    je change_background
    cmp al, 'p'                 ; Pause/unpause the game
    je toggle_pause
no_key_pressed:
    ret

; Toggle Pause or Unpause the game
toggle_pause:
    mov al, [paused]
    xor al, 1            ; change paused state (0 -> 1, 1 -> 0)
    mov [paused], al
    ret

;====================================== Move Player 1's paddle up ===============================
move_player1_up:
    cmp word [player1_y_position], 160           ; Top boundary
    jle no_key_pressed
    call clear_paddles_area
    sub word [player1_y_position], 160           ; Move up
    call draw_paddles_on_screen
    ret

; Move Player 1's paddle down
move_player1_down:
    cmp word [player1_y_position], 3360          ; Bottom boundary
    jge no_key_pressed
    call clear_paddles_area
    add word [player1_y_position], 160           ; Move down 
    call draw_paddles_on_screen
    ret

; Move Player 2's paddle up
move_player2_up:
    cmp word [player2_y_position], 318           ; Top boundary
    jle no_key_pressed
    call clear_paddles_area
    sub word [player2_y_position], 160           ; Move up 
    call draw_paddles_on_screen
    ret

; Move Player 2's paddle down
move_player2_down:
    cmp word [player2_y_position], 3518           ; Bottom boundary
    jge no_key_pressed
    call clear_paddles_area
    add word [player2_y_position], 160            ; Move down
    call draw_paddles_on_screen
    ret
;=======================Display Score on the Top of Screen==============================
display_score:
    mov ax, 0xb800
    mov es, ax
    mov di, 0              ; Start top left corner

; Clear the score area
mov cx, 80             ; Clear 80 characters 
clear_score_area:
    mov word [es:di], 0x0720 ; Clear space 
    add di, 2              ; Move to the next character position
    loop clear_score_area

; Display Player 1's score
mov di, 70            ; Position for Player 1's score 
mov al, [player1_score]
add al, '0'            ; Convert to ASCII
mov ah, 0x06           ; Green text on black background 
mov [es:di], ax        ; Display Player 1's score

; Display colon separator
mov di, 72             ; Position for colon separator 
mov al, ':'            ; ASCII for colon
mov ah, 0x07           ; White text on black background
mov [es:di], ax        ; Display colon

; Display Player 2's score
mov di, 74             ; Position for Player 2's score 
mov al, [player2_score]
add al, '0'            ; Convert to ASCII
mov ah, 0x06           ; green text on black background 
mov [es:di], ax        ; Display Player 2's score
ret

; ====================================Check Winner ====================================
check_winner:
    mov al, [player1_score]   ; Load Player 1's score
    cmp al, [winning_score]   ; Compare with winning score
    je player1_wins          

    mov al, [player2_score]   ; Load Player 2's score
    cmp al, [winning_score]   ; Compare with winning score
    je player2_wins           

    ret                    

player1_wins:
    ; Display Player 1 wins message
    call clear_screen         ; Clear the screen
    mov bx, msg_player1_wins
    mov di, 1000              ; Location
    call print_msg
    call display_restart_exit ; Prompt for restart or exit
    ret

player2_wins:
    ; Display Player 2 wins message
    call clear_screen         ; Clear the screen
    mov bx, msg_player2_wins
    mov di, 1000              ; Location
    call print_msg
    call display_restart_exit ; Prompt for restart or exit
    ret

;==============================Display Restart / Exit the Game=========================
display_restart_exit:
    mov bx, msg_restart
    mov di, 1160              ; Location
    call print_msg
wait_restart_exit:
    mov ah,0x00
	int 0x16
    cmp al, 'r'               ; Check if 'r' is pressed
    je start                  ; Restart the game
    cmp al, 'e'               ; Check if 'e' is pressed
    je end_game               ; Exit the game
    jmp wait_restart_exit     ; Wait for valid input

end_game:
    mov ax,0x4c00
	int 0x21

;============================================ Start label =================================
start:
    ;=========for Reset game state =====================
    mov word [player1_y_position], 0     ; Reset paddle positions
    mov word [player2_y_position], 318
    mov word [ball_pos_x], 40           ; Reset ball to center
    mov word [ball_pos_y], 12
    mov byte [player1_score], 0         ; Reset scores
    mov byte [player2_score], 0
  
    call clear_screen
    call set_initial_velocity
    call draw_wall
    ; =================Display Instructions messages before game start ====================
    mov bx, msg0
    mov di, 830         ; Row 10, column 10
    call print_msg

    mov bx, msg1
    mov di, 1150        ; Row 15, column 10
    call print_msg

    mov bx, msg2
    mov di, 1630        ; Row 20, column 10
    call print_msg

    mov bx, msg3
    mov di, 2270        ; Row 25, column 10
    call print_msg

    mov bx, msg4
    mov di, 2750        ; Row 20, column 10
    call print_msg

    ; Wait for Enter key
    call wait_to_press
    call clear_screen   
    call draw_wall

    mov bx, menu0
    mov di, 322
    call print_msg

    mov bx, menu1
    mov di, 482
    call print_msg

    mov bx, menu2
    mov di, 642
    call print_msg

    mov bx, menu3
    mov di, 802       
    call print_msg

    ; Wait for Enter key
    call wait_to_press
    call clear_screen
jmp game_loop

;============================================ Game label ====================================
game_loop:
    cmp byte [paused], 1    ; Check if the game is paused
    je paused_state       

    call handle_input       
    call move_ball          
    call draw_paddles_on_screen
    call display_score     
    call check_winner        
    jmp game_loop

paused_state:
    ; If the game is paused, just display the screen and allow the player to resume
    call draw_paddles_on_screen
    call display_score    
    call handle_input     
    jmp game_loop         
	
;================================= Delay for Game ===========================
mov cx, 0xFFFF
delay_loop:
    loop delay_loop
    jmp game_loop           ; Repeat the main loop