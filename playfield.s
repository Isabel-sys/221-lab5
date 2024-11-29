draw_level: 
  pushq %rbp   

  movl %edi           , %edx 
  leaq levelfmt(%rip) , %rsi 
  leaq labelbuf(%rip) , %rdi 
  call sprintf 

  leaq labelbuf(%rip) , %rdx 
  xorl %edi           , %edi 
  xorl %esi           , %esi 
  call mvprintw 

  popq %rbp 
  ret 

draw_score: 
  pushq %rbp 

  movl %edi           , %edx 
  leaq scorefmt(%rip) , %rsi 
  leaq labelbuf(%rip) , %rdi 
  call sprintf 

  leaq labelbuf(%rip) , %rdi 
  call strlen 

  leaq labelbuf(%rip) , %rdx 
  movl $80            , %esi 
  subl %eax           , %esi 
  shrl $1             , %esi 
  xorl %edi           , %edi 
  call mvprintw

  popq %rbp 
  ret 

draw_segments: 
  pushq %rbp 

  movl %edi           , %edx 
  leaq segmtfmt(%rip) , %rsi 
  leaq labelbuf(%rip) , %rdi 
  call sprintf 

  leaq labelbuf(%rip) , %rdi 
  call strlen 

  leaq labelbuf(%rip) , %rdx 
  movl $80            , %esi 
  subl %eax           , %esi 
  xorl %edi           , %edi 
  call mvprintw 
  
  popq %rbp 
  ret 


draw_header: 
  pushq %rbp 
  movq  %rdi , %rbp 

  movl $4 , %edi 
  call color_on 

  movl 16(%rbp) , %edi 
  call draw_level

  movl 20(%rbp) , %edi 
  call draw_score

  movl 24(%rbp) , %edi 
  call draw_segments

  movl $4 , %edi 
  call color_off

  popq %rbp 
  ret 

draw_banner: 
  pushq %rbp 
  movq  %rdi , %rbp 

  movl $1 , %edi 
  call color_on 

  movq %rbp , %rdi 
  call strlen 

  movl $80  , %esi 
  subl %eax , %esi 
  shrl $1   , %esi 
  movl $1   , %edi 
  movq %rbp , %rdx 
  call mvprintw 

  movl $1 , %edi 
  call color_off 

  popq %rbp 
  ret 

render_border: 
  pushq %rbp 

  movl $1   , %edi 
  movl $0   , %esi 
  movl $']' , %edx 
  movl $24  , %ecx 
  call mvvline 

  movl $1   , %edi 
  movl $1   , %esi 
  movl $'=' , %edx 
  movl $78  , %ecx 
  call mvhline 

  movl $24  , %edi 
  movl $1   , %esi 
  movl $'=' , %edx 
  movl $78  , %ecx 
  call mvhline 

  movl $1   , %edi 
  movl $79  , %esi 
  movl $'[' , %edx 
  movl $24  , %ecx 
  call mvvline 
  

  popq %rbp 
  ret 

# === render entity === 
# @brief given a Node representing 
#        an entity and a Game object 
#        use the offset,character,... 
#        described in the game object 
#        to display the entity 
render_entity: 
  pushq %rbp 

  movq %rsi , %rbp 

  cmpl $0 , 20(%rdi)
  je 2f 

  # char c = Game.char_arr[Node.kind]
  movq 8(%rbp)     , %rcx 
  movl 16(%rdi)    , %edx
  movb (%rcx,%rdx) , %dl 

  # int x = Node.x + Game.offset.x 
  # int y = Node.y + Game.offset.y 
  # mvaddch(y,x,c)
  movl 8(%rdi)  , %esi 
  addl (%rbp)   , %esi 
  movl 12(%rdi) , %edi 
  addl 4(%rbp)  , %edi 
  call mvaddch 
2: 
  popq %rbp 
  ret 


# === render entities === 
# @brief given a List representing 
#        entities in a game and a 
#        Game object, render the entire 
#        list 
render_entities: 
  pushq %rbp 
  pushq %rbx 
  pushq %rbp 

  movq %rdi , %rbp 
  movq %rsi , %rbx 

  movl $1 , %edi 
  call color_on 

  movq (%rbp) , %rdi 
  movq %rbx   , %rsi 
  leaq render_entity(%rip) , %rdx 
  call iter_nodes 

  movl $1 , %edi 
  call color_off 


  movl $2 , %edi 
  call color_on 


  movq 8(%rbp) , %rdi 
  movq %rbx    , %rsi
  leaq render_entity(%rip) , %rdx 
  call iter_nodes

  movl $2 , %edi 
  call color_off 

  popq %rbp 
  popq %rbx 
  popq %rbp 
  ret 



# === random range === 
# @brief given a range [x,y]
#        produce a random number 
#        such that x <= n <= y 
rand_range: 
  pushq %rbp 

  call unpack_vec 

  movl %edx , %ebp 
  subl %eax , %ebp 
  incl %ebp 
  addl %eax , %ebp 

  

  call rand 
  xorl %edx , %edx 
  cqo 
  divl %ebp 

  movl %edx , %eax 

  popq %rbp 
  ret 

# === rand coords === 
# @brief produce a random set 
#        of coordinates in the game world 
rand_coords: 
  pushq %rbp 


  movq bounds_x , %rdi 
  call rand_range

  movl %eax , %ebp 

  movq bounds_y , %rdi 
  call rand_range 

  movl %ebp , %edi 
  movl %eax , %esi 
  call pack_vec


  popq %rbp 
  ret 


entity_collision: 
  pushq %rbp 
  pushq %rbx 

  movq %rdi , %rbp 
  movq %rsi , %rbx 

  movq (%rbp) , %rdi 
  movq %rbx   , %rsi 
  call collision
  testq %rax , %rax 
  jnz 1f 

  movq 8(%rbp) , %rdi 
  movq %rbx    , %rsi 
  call collision


1: 
  popq %rbx 
  popq %rbp 
  ret 


new_object: 
  pushq %rbp 
  pushq %rbx 
  pushq %r12 
  pushq %r14 

  movq %rdi , %rbp 
  movq %rsi , %rbx 
  movl %edx , %r12d 

1: 
  call rand_coords  
  movq %rax , %r14 

  movq  (%rbp) , %rdi 
  movq  %r14   , %rsi
  call  collision 
  testq %rax , %rax 
  jnz   1b 

  movq 8(%rbp) , %rdi 
  movq %r14    , %rsi 
  call collision
  testq %rax , %rax 
  jnz 1b 

  movq  (%rbx) , %rdi 
  movq  %r14   , %rsi 
  call  collision
  testq %rax , %rax 
  jnz   1b 

  movq $24 , %rdi 
  call malloc 

  movq $0    ,   (%rax)
  movq %r14  ,  8(%rax)
  movl %r12d , 16(%rax)
  movl $1    , 20(%rax)

  leaq (%rbp,%r12,8) , %rdi 
  movq %rax , %rsi 
  call append 
  
  popq %r14 
  popq %r12 
  popq %rbx 
  popq %rbp 
  ret

init_entities: 
  pushq %rbp 
  pushq %rbx 
  pushq %r12 


  movq %rdi , %rbp 
  movq %rsi , %rbx 

  xorq %r12 , %r12 

1: 

  movq %rbp , %rdi 
  movq %rbx , %rsi 
  movl $0   , %edx 
  call new_object

  incq %r12 
  cmpq $4 , %r12 
  jne 1b


  movq %rbp , %rdi 
  movq %rbx , %rsi 
  movl $1   , %edx 
  call new_object


  popq %r12
  popq %rbx 
  popq %rbp 
  ret 

# regen(node,(list,snake))
regen: 
  pushq %rbp 
  pushq %rbx 
  pushq %r12 


  movq %rdi , %rbp 
  movq %rsi , %rbx 


1: 
  call rand_coords
  movq %rax , %r12 

  movq  (%rbx) , %rdi 
  movq  (%rdi) , %rdi 
  movq  %r12   , %rsi 
  call  collision
  testq %rax , %rax 
  jnz   1b

  movq  (%rbx) , %rdi 
  movq  8(%rdi) , %rdi 
  movq  %r12    , %rsi 
  call  collision
  testq %rax , %rax 
  jnz   1b 

  movq  8(%rbx) , %rdi 
  movq  (%rdi)  , %rdi 
  movq  %r12    , %rsi 
  call  collision
  testq %rax , %rax 
  jnz   1b 

  movq %r12 ,  8(%rbp)
  movl $1   , 20(%rbp)

  popq %r12 
  popq %rbx 
  popq %rbp 
  ret

# regen_list(list,snake)
regen_list: 
  pushq %rbp 
  movq  %rsp , %rbp 
  subq  $16  , %rsp 


  movq %rdi , -16(%rbp)
  movq %rsi , -8(%rbp)

  # iter_nodes(entities.apples,(entities,snake),&regen);
  movq (%rdi)      , %rdi 
  leaq -16(%rbp)   , %rsi
  leaq regen(%rip) , %rdx 
  call iter_nodes


  movq %rbp , %rsp 
  popq %rbp 
  ret 


next_level: 
  pushq %rbp 
  pushq %rbx 


  movq %rdi , %rbp 
  movq %rsi , %rbx 

  movq %rbp , %rdi 
  movq %rbx , %rsi 
  call regen_list

  movq %rbp , %rdi 
  movq %rbx , %rsi 
  xorl %edx , %edx 
  call new_object
  movq %rbp , %rdi 
  movq %rbx , %rsi 
  movq $1   , %rdx 
  call new_object


  popq %rbx 
  popq %rbp   
  ret 


check_obj_collision: 
  ret 
free_entities: 
  pushq %rbp 
  movq  %rdi , %rbp 

  movq (%rbp) , %rdi 
  call free_list 

  movq 8(%rbp) , %rdi 
  call free_list
  popq %rbp 
  ret

.globl render_entities
.globl next_level
.globl render_border
.globl init_entities
.globl free_entities
.globl draw_header
.globl draw_banner
