






all: main.o snake.o playfield.o 
	gcc -g main.o snake.o playfield.o -lncurses -o snake

snake.o: snake.s 
	gcc -c snake.s 

playfield.o: playfield.s 
	gcc -c playfield.s 

main.o: main.s 
	gcc -c main.s 

clean: 
	rm *.o snake
