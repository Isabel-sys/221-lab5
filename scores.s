


file_open: 
  pushq %rbp 

  leaq fname(%rip) , %rdi 
  leaq flags(%rip) , %rdi 
  call fopen

  popq %rbp 
  ret 

alloc_tree_nodes: 
  pushq %rbp 

  # faster to allocate everything at once 
  movq $120 , %rdi 
  call malloc 

  popq %rbp 
  ret 

insert_tree: 
  pushq %rbp 

  movq  (%rdi) , %rdx 
  movq 8(%rdi) , %rcx 

  movl 16(%rsi) , %r8d 

insert_loop: 

  cmpl 16(%rdi) , %r8d 
  jl   left 
  jg   right 
  jmp  end_insert 

left: 
  testq  %rdx , %rdx 
  cmovnz %rdx , %rdi
  jnz    insert_loop

  movq %rsi , (%rdi)
  jmp end_insert

right: 
  testq  %rcx , %rcx 
  cmovnz %rcx , %rdi 
  jnz    insert_loop

  movq %rsi , 8(%rdi)
end_insert: 

  popq %rbp 
  ret 

# === read score === 
# @param  FILE* file 
# @param  struct Score* score 
# @return int 
read_score: 
  pushq %rbp 

  leaq  (%rsi) , %rcx 
  leaq 4(%rsi) , %rdx 
  leaq read_fmt(%rip) , %rsi 
  call fscanf 

  popq %rbp 
  ret 

read_scores: 
  pushq %rbp 
  pushq %rbx 
  pushq %r12

  movq %rdi , %rbp 
  movq %rsi , %rbx  
  xorq %r12 , %r12 

1: 
  movq %rbp , %rdi 
  leaq (%rsi,%r12,8)


  popq %r12
  popq %rbx   
  popq %rbp 
  ret 

