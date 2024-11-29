.section .data 
  vecfmt : .asciz "(%d,%d)\n"


  Entities : .quad 0 , 0 
  Snake    : .quad 0 , 0 

  letters : .asciz "imjk"
  numbers : .asciz "8246"

  timer : .long 200000
  Game : 
    .long 1 , 2 # 0   
    .quad chars # 8 
    .long 1 , 0 , 4 , 0 

  move_jt : 
    .quad up 
    .quad down 
    .quad left 
    .quad right 
    .quad none 

  chars : .asciz "@X"

  eaten  : .quad 0 
  to_eat : .quad 4 

  bounds_x : .long 0 , 77 
  bounds_y : .long 0 , 21 

  dir_up    : .long  0 , -1 
  dir_down  : .long  0 ,  1 
  dir_left  : .long -1 ,  0 
  dir_right : .long  1 ,  0 
  dir_curr  : .long  1 ,  0


  .equ COLOR_BLACK   , 0b000 
  .equ COLOR_RED     , 0b001 
  .equ COLOR_GREEN   , 0b010 
  .equ COLOR_YELLOW  , 0b011
  .equ COLOR_BLUE    , 0b100 
  .equ COLOR_MAGENTA , 0b101 
  .equ COLOR_CYAN    , 0b110 
  .equ COLOR_WHITE   , 0b111

  scorefmt : .asciz "Score %06d"
  levelfmt : .asciz "Level %d"
  segmtfmt : .asciz "%d Segments"

  blank_record : .asciz "___ 000000"
  record_fmt   : .asciz "%s %06d"

  start_banner : .asciz "Press key to start"
  end_banner   : .asciz "Done, press key to exit"
  end_fmt : .asciz "Your score was %d\nYour snake had %d segments\nYou made it to level %d\n"

  fname : .asciz "scores.txt"
  flags : .asciz "r+"
  read_fmt : .asciz "%s %d"
  write_fmt : .asciz "%s %06d\n"

.section .bss 
  labelbuf : .space 20 , 0x00 
.section .text 
  .globl main 

  .globl bounds_x 
  .globl bounds_y

  .globl labelbuf
  .globl scorefmt 
  .globl levelfmt 
  .globl segmtfmt

  .globl read_fmt
  .globl write_fmt
  .globl fname
  .globl flags

# === decrement timer === 
# @brief  use fixed point arithmetic to 
#         decrement the timer by 20% 
#         100% - 20% = 80% , timer * 0.8 = timer * (8/10) = 
#         (timer * 8) / 10 
# @param  int time 
# @return int 
dec_timer: 
  movl %edi , %eax 
  movl $98  , %edi 
  mull %edi 

  movl $100 , %edi 

  divl %edi 

  ret 

# === end message === 
# @brief  display score, snake length , 
#         and level at the end of the current 
#         game 
# @param  struct Game* game 
# @return void 
end_msg: 
  pushq %rbp 

  movl 20(%rdi) , %esi 
  movl 24(%rdi) , %edx 
  movl 16(%rdi) , %ecx
  leaq end_fmt(%rip) , %rdi 
  call printf 

  popq %rbp  
  ret 

# === pack vector === 
# @brief  given two 4 byte integers x and y 
#         pack them into one quad using the 
#         formula (x | (y << 32)) to produce  
#         a vector 
# @param  int x 
# @param  int y 
# @return struct Vector vec 
pack_vec: 
  movl %edi , %eax 
  shlq $32  , %rsi 
  orq  %rsi , %rax 
  ret 

# === unpack vector === 
# @brief  given a 8 byte integer, 
#         unpack it into two 4 byte 
#         numbers using the formula 
#         x = vec & 0xFFFFFFFF
#         y = (vec >> 32) & 0xFFFFFFFF
# @param  struct Vector vec 
# @return (int , int )
unpack_vec: 
  movl %edi , %eax 
  shrq $32  , %rdi 
  movl %edi , %edx 
  ret 

# === vector add === 
# @brief  given vectors v1 , v2 
#         add them together to 
#         produce vector v3 s.t. 
#         v3 = {v1.x + v2.x , v1.y + v2.y}
# @param  struct Vector v1 
# @param  struct Vector v2 
# @return struct Vector
vec_add: 
  pushq %rbp 

  movq %rsi , %rbp 

  call unpack_vec

  addl %ebp , %eax 
  shrq $32  , %rbp 
  addl %ebp , %edx 

  movl %eax , %edi 
  movl %edx , %esi 
  call pack_vec 

  popq %rbp 
  ret 
  
# === iterate nodes === 
# @brief  given a linked list L  along 
#         with a memory address m containing 
#         an unknown amount of additional elements 
#         and a function f(L,m_1,m_2,m_3,...)
#         call the function f using every node in the list 
# @param  struct Node* list 
# @param  void* additional_args 
# @param  void (*f)(struct Node*,void*)
# @return void 
iter_nodes: 
  pushq %rbp 
  pushq %rbx 
  pushq %r12 

  movq %rdi , %rbp 
  movq %rsi , %rbx 
  movq %rdx , %r12
1: 
  testq %rbp , %rbp 
  jz    2f  


  movq %rbp , %rdi 
  movq %rbx , %rsi 
  call *%r12


  movq (%rbp) , %rbp 
  jmp  1b 
2: 
  popq %r12 
  popq %rbx 
  popq %rbp
  ret 

# === collision === 
# @brief given a vector and a linked list 
#        check the elements of the linked 
#        list to see if they are where the 
#        vector is, and return the node if so 
# @param  struct Node* list 
# @param  struct Vector vec 
# @return struct Node*
collision: 
  xorq %rax , %rax 
1: 
  testq %rdi , %rdi 
  je    2f 

  cmpq  %rsi , 8(%rdi)
  cmove %rdi , %rax 
  je    2f 


  movq (%rdi) , %rdi 
  jmp  1b 
2: 
  ret 

# === append === 
# @brief  given a linked list 
#         iterate to the last element of the 
#         list and then append a node 
# @param  struct Node* list 
# @param  struct Node* n 
# @return void 
append: 
1: 
  cmpq $0 , (%rdi)
  je 2f 

  movq (%rdi) , %rdi 
  jmp 1b 
2: 
  movq %rsi , (%rdi)
  ret 

free_list: 
  pushq %rbp 
  movq  %rdi , %rbp

1: 
  testq %rbp , %rbp 
  jz 2f 

  movq %rbp   , %rdi 
  movq (%rbp) , %rbp
  call free 
  jmp 1b 
2: 

  popq %rbp 
  ret 


# === get position === 
# @brief  simple sequential search 
# @param  char* possible_inputs 
# @param  char  input 
# @return int
get_pos: 
  xorq %rcx , %rcx 
1: 
  cmpq $4 , %rcx 
  je 2f 

  cmpb (%rdi,%rcx) , %sil 
  je   2f 

  incq %rcx 
  jmp 1b 
2: 

  movq %rcx , %rax 
  ret 

# === check movement === 
# @brief  given a list of possible 
#         movement keys and an input 
#         along with the current direction 
#         the snake is travelling, check to 
#         see if the direction needs to be changed
# @param  char* possible inputs 
# @param  char  input 
# @param  struct Vector vec 
# @return struct Vector vec 
check_movement: 
  pushq %rbp 
  movq  %rdx , %rbp 

  movq %rdi , %rdi 
  movb %sil , %sil 
  call get_pos


  leaq move_jt(%rip) , %rcx 
  jmp *(%rcx,%rax,8)

up: 
  cmpq dir_down , %rbp 
  je   none 

  movq dir_up , %rbp
  jmp  none 
down: 
  cmpq dir_up , %rbp 
  je   none 
  movq dir_down , %rbp
  jmp  none 
left: 
  cmpq dir_right , %rbp 
  je   none 
  movq dir_left , %rbp 
  jmp  none 
right: 
  cmpq dir_left , %rbp 
  je   none 
  movq dir_right , %rbp 
  jmp  none 
none: 
  movq %rbp , %rax 
  popq %rbp 
  ret 



# === color on === 
# @brief  given a color pair index, 
#         enable that pair 
# @param  int pair 
# @return void 
color_on: 
  pushq %rbp 

  shll $8   , %edi 
  xorl %esi , %esi 
  call attr_on

  popq %rbp 
  ret 

# === color off === 
# @brief  given a color pair index, 
#         disable that pair 
# @param  int pair 
# @return void 
color_off: 
  pushq %rbp 

  shll $8   , %edi 
  xorl %esi , %esi 
  call attr_off

  popq %rbp 
  ret 
  movq %r15 , %rdi 
  call check_bounds 
  testq %rax , %rax 
  jnz 1f 




# === init system === 
# @brief  initialize data structures and logic 
#         such as the Snake, the Entities array 
#         and randomization 
# @param  struct Snake*   snake 
# @param  struct Entity** Entities
# @return void 
init_sys: 
  pushq %rbp 
  pushq %rbx 

  movq %rdi , %rbp 
  movq %rsi , %rbx 

  movl $0 , %edi 
  call time 

  movl %eax , %edi 
  call srand  
  
  movq %rbp , %rdi 
  call init_snake 

  movq %rbx , %rdi 
  movq %rbp , %rsi 
  call init_entities

  popq %rbx
  popq %rbp 
  ret 

# === init graphics === 
# @brief  initialize ncurses 
# @return void 
init_graphic: 
  pushq %rbp 

  call initscr 

  movl $0 , %edi 
  call curs_set

  call noecho 
  call cbreak 

  call start_color 

  movl $1 , %edi 
  movl $COLOR_RED   , %esi 
  movl $COLOR_BLACK , %edx 
  call init_pair 

  movl $2 , %edi 
  movl $COLOR_BLACK , %esi 
  movl $COLOR_BLUE  , %edx 
  call init_pair


  movl $3 , %edi 
  movl $COLOR_YELLOW , %esi 
  movl $COLOR_BLACK  , %edx 
  call init_pair

  movl $4 , %edi 
  movl $COLOR_MAGENTA , %esi 
  movl $COLOR_BLACK   , %edx 
  call init_pair

  popq %rbp 
  ret 

# === enable timer === 
# @brief  disable getch() blocking 
#         for main gameplay loop 
# @return void 
enable_timer: 
  pushq %rbp 

  movq stdscr@GOTPCREL(%rip) , %rdi 
  movq (%rdi)                , %rdi 
  movq $1                    , %rsi 
  call nodelay 

  popq %rbp 
  ret 

# === disable timer === 
# @brief  enable getch() blocking 
#         mainly just for pausing 
#         and end of round 
# @return void 
disable_timer: 
  pushq %rbp 

  movq stdscr@GOTPCREL(%rip) , %rdi 
  movq (%rdi)                , %rdi 
  xorq %rsi                  , %rsi 
  call nodelay 

  popq %rbp 
  ret 


# === pause === 
# @brief  stop main gameplay loop for debug 
# @return void 
pause: 
  pushq %rbp 

  call disable_timer
1: 
  call getch 
  cmpl $'p' , %eax 
  jne  1b 

  call enable_timer

  popq %rbp 
  ret 

# === teardown graphics === 
# @brief  stop ncurses and return 
#         to original terminal 
#         configuration 
# @return void 
tear_graphic: 
  pushq %rbp 

  call endwin 

  popq %rbp 
  ret 

# === frame === 
# @brief  draw the current frame 
# @param  struct Game* game 
# @param  struct Snake* snake 
# @param  struct Entity** entities 
# @return void 
frame: 
  pushq %rbp 
  pushq %rbx 
  pushq %r12 


  movq %rdi , %rbp 
  movq %rsi , %rbx 
  movq %rdx , %r12

  call clear 
  call render_border

  movq %rbp , %rdi 
  call draw_header

  movq %rbx , %rdi 
  movq %rbp , %rsi 
  call render_snake 

  movq %r12 , %rdi 
  movq %rbp , %rsi 
  call render_entities

  call refresh 

  popq %r12 
  popq %rbx 
  popq %rbp 
  ret


# === frame_logic === 
# @brief perform all the logic required 
#        for the current frame 
#        and return if the game is over 
# @param struct Game*  game 
# @param struct Snake* snake
# @param struct Vector* direction
# (this needs to be a pointer so next frame 
#  can see the updated direction from the current) 
# @param  char input 
# @return bool 
frame_logic:
  pushq %rbp 
  pushq %rbx 
  pushq %r12 
  pushq %r13 
  pushq %r14 
  pushq %r15 

  movq %rdi , %rbp 
  movq %rsi , %rbx 
  movq %rdx , %r12 
  movq %rcx , %r13 
  movb %r8b , %r14b 

  # === begin check input === 

  leaq letters(%rip) , %rdi 
  movb %r14b         , %sil
  movq (%r13)        , %rdx 
  call check_movement
  movq %rax , (%r13)

  leaq numbers(%rip) , %rdi 
  movb %r14b         , %sil 
  movq (%r13)        , %rdx 
  call check_movement
  movq %rax , (%r13)

  # === end check input === 

  # === begin calculate next position === 

  movq %rbx , %rdi 
  call head_pos 

  movq %rax   , %rdi 
  movq (%r13) , %rsi 
  call vec_add
  movq %rax , %r15 

  # === end calculate next position === 

  # === check apple collision === 
  movq (%r12) , %rdi 
  movq %r15   , %rsi 
  call  collision
  testq %rax , %rax 
  jz    skip_eat 


  cmpl $0 , 20(%rax)
  je   skip_eat

  movl 16(%rbp) ,     %edi 
  addl %edi     , 20(%rbp)
  addl $1       , 24(%rbp)
  addq $1       , eaten
  movl $0       , 20(%rax)

  movq %rbx , %rdi 
  movq %r15 , %rsi 
  call grow

  movq eaten , %rax 
  cmpq %rax  , to_eat
  jne  skip_move

  movl $0 , eaten
  addq $1 , to_eat
  addl $1 , 16(%rbp)

  movq %r12 , %rdi 
  movq %rbx , %rsi 
  call next_level

  call beep 

  movl timer , %edi 
  call dec_timer
  movl %eax , timer


  # if we know that we've collided with an apple,  
  # it is impossible to collide with anything else 
  jmp skip_move
skip_eat: 
  # === end calculate apple collision === 


  # === begin calculate game end === 

  # if we collide with an obstacle, 
  # a snake, or a wall, then it's all 
  # the same behavior 

  movq  (%rbx) , %rdi 
  movq  (%rbx) , %rdi 
  movq  %r15   , %rsi 
  call  collision
  testq %rax , %rax 
  jnz   1f 

  movq  8(%r12) , %rdi 
  movq  %r15    , %rsi 
  call  collision
  testq %rax , %rax 
  jnz   1f

  movq  %r15 , %rdi 
  call  check_bounds 
  testq %rax , %rax 
  jnz   1f 

  # === end calculate game end  === 

 # game not ended && apple not eaten => move to next position 

  movq %rbx , %rdi 
  movq %r15 , %rsi 
  call move 

skip_move: 
  # if we havent hit a obstacle, xor out rax 
  # to tell the main loop we keep playing 
  # otherwise we exit the game 
  xorq %rax , %rax 
1: 
  popq %r15 
  popq %r14 
  popq %r13 
  popq %r12 
  popq %rbx 
  popq %rbp 
  ret 


main: 
  pushq %rbp 

  leaq Snake(%rip)    , %rdi 
  leaq Entities(%rip) , %rsi 
  call init_sys

  call init_graphic


  # render initial frame for start of game 

  leaq Game(%rip)     , %rdi 
  leaq Snake(%rip)    , %rsi 
  leaq Entities(%rip) , %rdx 
  call frame 

  leaq start_banner(%rip) , %rdi 
  call draw_banner 


wait_start: 
  call getch 
  movl %eax , %ebp 

  leaq numbers(%rip) , %rdi 
  movb %al           , %sil
  call get_pos 
  cmpl $4 , %eax 
  jne  start

  movl %ebp , %eax 

  leaq letters(%rip) , %rdi 
  movb %al           , %sil 
  call get_pos
  cmpl $4 , %eax 
  jne  start

  jmp wait_start 

  # end initial frame 

# start main gameplay loop
start: 
  # ebp holds the latest input from before the gameplay 
  # loop, we use this to make sure that the players first 
  # directional input (the one which starts the game) is 
  # correctly processed 
  movl %ebp , %eax

  leaq numbers(%rip) , %rdi 
  movb %al           , %sil 
  movq dir_curr      , %rdx 
  call check_movement
  movq %rax , dir_curr

  movl %ebp , %eax 

  leaq letters(%rip) , %rdi 
  movb %al           , %sil 
  movq dir_curr      , %rdx 
  call check_movement
  movq %rax , dir_curr

  # start main gameplay loop by 
  # disabling blocking 
  call enable_timer
main_loop: 
  call getch 
  # p pressed => pause the game 
  cmpl $'p' , %eax 
  jne  no_pause

  call pause 

no_pause: 

  # calculate logic for current frame 
  leaq Game(%rip)  , %rdi 
  leaq Snake(%rip) , %rsi 
  leaq Entities(%rip) , %rdx 
  leaq dir_curr(%rip) , %rcx 
  movb %al            , %r8b
  call frame_logic

  # if frame_logic(game,snake,entities,dir,input) , end game 
  testq %rax , %rax 
  jnz   end_main_loop


  # render the current frame 
  leaq Game(%rip) , %rdi 
  leaq Snake(%rip) , %rsi 
  leaq Entities(%rip) , %rdx 
  call frame

  # set framerate 
  movl timer , %edi
  call usleep

  jmp main_loop
end_main_loop:
  # renable blocking for end 
  call disable_timer

  leaq end_banner(%rip) , %rdi 
  call draw_banner

  call getch


  call tear_graphic
  leaq Game(%rip) , %rdi 
  call end_msg

  leaq Snake(%rip) , %rdi 
  call free_snake 

  leaq Entities(%rip) , %rdi 
  call free_entities
  
  popq %rbp 

  ret 

.globl collision

.globl iter_nodes
.globl append
.globl free_list

.globl pack_vec
.globl unpack_vec

.globl color_on 
.globl color_off

