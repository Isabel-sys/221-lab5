


# === push head === 
# @brief  push a new 'head' 
#         to the snake 
# @param  struct Snake*  snake 
# @param  struct Segment* segment 
# @return void
push_head: 
  cmpq $0 , (%rdi)
  je 1f 

  movq (%rdi) , %rdx 
  movq %rsi   , 16(%rdx)
  movq %rdx   , (%rsi)
  movq %rsi   , (%rdi)

  jmp 2f 
1: 
  movq %rsi ,  (%rdi)
  movq %rsi , 8(%rdi)

2: 
  ret 

# === push tail === 
# @brief  push a new 'tail' 
#         to the snake 
# @param  struct Snake* snake 
# @param  struct Segment* segment 
# @return void 
push_tail: 
  cmpq $0 , 8(%rdi)
  je 1f 

  movq 8(%rdi) ,     %rdx 
  movq %rsi    ,   (%rdx)
  movq %rdx    , 16(%rsi)
  movq %rsi    ,  8(%rdi)

  jmp 2f 

1: 
  movq %rsi ,  (%rdi)
  movq %rsi , 8(%rdi)
2: 
  ret 

# === pop tail === 
# @brief  "disconnect" the tail 
#         from the snake and return the 
#         pointer to the tail, returns null 
#         if there is no tail 
# @param  struct Snake* snake 
# @return struct Segment* segment
pop_tail: 
  movq 8(%rdi) , %rax 
  testq %rax , %rax 
  jz 2f 

  movq  16(%rax) , %rdx 
  testq %rdx , %rdx 
  jz 1f 

  movq $0 ,    (%rdx)
  movq %rdx , 8(%rdi)

  jmp 2f 
1: 
  movq $0 ,  (%rdi)
  movq $0 , 8(%rdi)
2: 
  ret

# === head position === 
# @brief  return a vector representing the position 
#         of the snake head 
# @param  struct Snake* snake 
# @return struct Vector
head_pos: 
  movq  (%rdi) , %rax 
  movq 8(%rax) , %rax 
  ret

new_segment: 
  pushq %rbp 

  movq %rdi , %rbp 

  movq $24 , %rdi 
  call malloc 

  movq $0   ,   (%rax)
  movq %rbp ,  8(%rax)
  movq $0   , 16(%rax)

  popq %rbp 
  ret 

# === free snake === 
# @brief  free the snake data structure 
# @param  struct Snake* snake 
# @return void 
free_snake: 
  pushq %rbp 

  movq %rdi , %rbp 
1: 

  movq  %rbp , %rdi 
  call  pop_tail
  testq %rax , %rax 
  jz    2f 

  movq %rax , %rdi 
  call free 

  jmp 1b 

2: 


  popq %rbp 
  ret 

# === initialize snake === 
# @brief  given a pointer, initialize the 
#         snake to the pointer, creating one 
#         with 4 segments with the head in the center 
# @param  struct Snake* snake 
# @return void 
init_snake: 
  pushq %rbp 
  pushq %rbx 


  movq %rdi , %rbp 
  movl $4 , %ebx 
1: 

  movl $35           , %edi 
  leal -1(%edi,%ebx) , %edi 
  movl $10           , %esi 
  call pack_vec

  movq %rax , %rdi 
  call new_segment

  movq %rbp , %rdi 
  movq %rax , %rsi 
  call push_tail

  decl  %ebx 
  testl %ebx , %ebx 
  jnz 1b 

  popq %rbx 
  popq %rbp 

  ret 


# === render segment === 
# @brief  render an individual segment 
# @param  struct Segment* segment 
# @return void 
render_segment: 
  pushq %rbp 

  movq %rsi , %rbp 

  movl 8(%rdi)  , %esi 
  addl (%rbp)   , %esi 
  movl 12(%rdi) , %edi 
  addl 4(%rbp)  , %edi 
  movl $'*'     , %edx 
  call mvaddch 

  popq %rbp 
  ret


# === grow === 
# @brief  grow the snake 
# @param  struct Snake* snake 
# @param  struct Vector vec 
# @return void
grow: 
  pushq %rbp 
  movq  %rdi , %rbp 
  movq %rsi , %rdi 
  call new_segment
  movq %rbp , %rdi 
  movq %rax , %rsi 
  call push_head
  popq %rbp 
  ret 

move: 
  pushq %rbp 
  pushq %rbx 

  movq %rdi , %rbp 
  movq %rsi , %rbx 

  call pop_tail

  movq $0   ,   (%rax)
  movq %rbx ,  8(%rax)
  movq $0   , 16(%rax)

  movq %rbp , %rdi 
  movq %rax , %rsi 
  call push_head

  popq %rbx 
  popq %rbp 
  ret 

check_bounds: 
  
  call unpack_vec 

  movl %eax , %esi 
  xorl %eax , %eax 
  movl $1   , %ecx

  cmpl $0    , %esi 
  cmovl %ecx , %eax 

  cmpl $77   , %esi 
  cmovg %ecx , %eax

  cmpl $0    , %edx 
  cmovl %ecx , %eax 

  cmpl $21   , %edx 
  cmovg %ecx , %eax 

  
  ret 


# === render snake === 
# @brief  render the snake by rendering the head 
#         then iterating and rendering the segments 
# @param  struct Snake* snake 
# @param  struct Game*  game 
# @return void 
render_snake: 
  pushq %rbp 
  pushq %rbx 
  pushq %rbp 

  movq (%rdi) , %rbp 
  movq %rsi , %rbx 

  movl $3 , %edi 
  call color_on 

  movl 8(%rbp)  , %esi 
  addl (%rbx)   , %esi 
  movl 12(%rbp) , %edi 
  addl 4(%rbx)  , %edi 
  movl $'O'     , %edx 
  call mvaddch 

  movq (%rbp) , %rdi 
  movq %rbx   , %rsi 
  leaq render_segment(%rip) , %rdx 
  call iter_nodes

  movl $3 , %edi 
  call color_off

  popq %rbp 
  popq %rbx 
  popq %rbp 
  ret 

.globl free_snake
.globl init_snake
.globl render_snake
.globl move
.globl grow 
.globl head_pos
.globl check_bounds
