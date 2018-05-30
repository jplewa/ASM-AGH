	assume cs:code1, ds:data1, ss:stack1
			
data1   segment
x_top	dw 150
score	dw 1
level	db 1
delay	dw 55000
hello1	 db "             XXXXXXXXXX   XXXXXXXXXX   XX      XX   XX   XXXXXXXXXX$"
hello2	 db "             XXXXXXXXXX   XXXXXXXXXX   XXX     XX   XX   XXXXXXXXXX$"
hello3	 db "                 XX       XX           XXXX    XX   XX   XX$"
hello4	 db "                 XX       XX           XXXXX   XX   XX   XX$"
hello5	 db "                 XX       XXXXXXXXXX   XX XXX  XX   XX   XXXXXXXXXX$"
hello6	 db "                 XX       XXXXXXXXXX   XX  XXX XX   XX   XXXXXXXXXX$" 
hello7	 db "                 XX       XX           XX   XXXXX   XX           XX$"
hello8	 db "                 XX       XX           XX    XXXX   XX           XX$"
hello9	 db "                 XX       XXXXXXXXXX   XX     XXX   XX   XXXXXXXXXX$"
hello10	 db "                 XX       XXXXXXXXXX   XX      XX   XX   XXXXXXXXXX$"
options1 db "Aby zmienic kolor pilki w trakcie gry, wcisnij C.$"
options2 db "Aby zmienic rozmiar pilki, wcisnij klawisz + lub -.$"
options3 db "Aby zapauzowac gre, wcisnij P.$"
options4 db "Aby wyjsc z gry, wcisnij ESC.$"
options5 db "Aby zaczac gre, wcisnij dowolny klawisz...$"
over	db "Niestety nie odbiles pilki. Twoj wynik to: $"
over2	db "Jesli chcesz zagrac jeszcze raz, wcisnij spacje.$"
over3 	db "Aby wyjsc z gry, wcisnij ESC.$"
radius	db 8
color	db 12
go		db 0
x		dw 0
y		dw 197
O_x		db 0
O_y		db 0
go_up	dw 0
go_down	dw 2
go_left	dw 0
go_right dw 0
ball_x	dw 165					
ball_y	dw 11
data1 	ends

code1   segment      					
start1: mov ax, seg top1     	        ; ustawiamy wskaznik i segment stosu
		mov ss, ax
		mov sp, offset top1
				
		mov ax, seg delay            ; ustawiamy ds:dx na poczatek segmentu danych
		mov ds, ax
		mov dx, offset delay

		mov ax, 0A000h
		mov es, ax						; es wskazuje na VGA
		
		mov al, 03h						; zaczynamy od wlaczenia trybu tekstowego (wyczyszczenia ekranu)
		mov ah, 0h
		int 10h
		
		call nl
		
		call tennis						; nazwa gry
		
		call nl
		call nl
		
		mov dx, offset options1
		mov ah, 09h
		int 21h
		
		call nl
		call nl
		
		mov dx, offset options2
		mov ah, 09h
		int 21h
		
		call nl
		call nl
		
		mov dx, offset options3
		mov ah, 09h
		int 21h

		call nl
		call nl
		
		mov dx, offset options4
		mov ah, 09h
		int 21h		
		
		call nl
		call nl
		
		mov dx, offset options5
		mov ah, 09h
		int 21h
		
		mov ah, 0h						; czekamy na nacisniecie klawicza, aby uruchomic gre
		int 16h
		
		
restart:mov al, 13h						; tryb graficzny 13h
		mov ah, 0h						; 320x240 256 kolorów
		int 10h
		
		mov	di,0						; stosw - slowo z ax do ES:DI
		mov	cx,(320*200)/2
		cld								; di bedzie inkrementowane
		mov	al, 08h
		mov	ah, al
		rep stosw

		mov byte ptr ds:[go], 0h		; jesli gra jest restartowana - ustawiamy lokalizacje pilki/paletki itd. na wartosci poczatkowe
		mov word ptr ds:[x], 0h
		mov word ptr ds:[y], 197d
		mov ah, 0h
		mov al, ds:[radius]
		add ax, 02h
		mov word ptr ds:[ball_y], ax
		mov word ptr ds:[ball_x], 165d
		mov word ptr ds:[x_top], 150d
		mov word ptr ds:[go_left], 0h
		mov word ptr ds:[go_right], 0h
		mov word ptr ds:[go_up], 0h
		mov word ptr ds:[go_down], 02h
		mov word ptr ds:[score], 01h
		mov byte ptr ds:[level], 01h

		call racket						; narysuj dolna paletke
		
		mov ax, word ptr ds:[y]
		push ax
		mov word ptr ds:[y], 0h
		
		mov ax, word ptr ds:[x]
		push ax
		
		mov ax, ds:[x_top]
		mov word ptr ds:[x], ax
		
		call racket						; narysuj paletke komputera
	
		pop ax
		mov word ptr ds:[x], ax
		pop ax
		mov word ptr ds:[y], ax
	
game:	mov ah, 01h						; sprawdzenie stanu bufora klawiatury
        int 16h
		jnz gotkey1
		
move_b: 
		call clear_b					; zmaz pilke z poprzedniej lokalizacji
		call move						; zaktualizuj polozenie, biorac pod uwage aktualna sciezke ruchu
		call ball						; narysuj pilke w nowej lokalizacji
		call top_racket_move			; przesun paletke komputera (zgodnie z ruchem pilki)
		
		mov al, byte ptr ds:[go]		; sprawdz, czy przegrales
		cmp al, 01h
		je lost
				
		mov ax, 5000d
		xor cx, cx
		mov cl, byte ptr ds:[level]
		cmp cx, 11d
		jbe skip
		mov cx, 11d
skip:	mul cx
		mov dx, word ptr ds:[delay]
		sub dx, ax
		
		xor cx, cx						; jesli nie, to poczekaj (plynnosc ruchow!)
		mov ah, 86h
		int 15h	
		
		jmp game
gotkey1: jmp gotkey	
restart1: jmp restart	
lost:									; w wypadku przegranej - najpierw wyczysc ekran
		mov	di,0						; stosw - slowo z ax do ES:DI
		mov	cx,(320*200)/2
		cld								; di bedzie inkrementowane
		mov	al, 0h
		mov	ah, al
		rep stosw

		mov	al, 3                       ; tryb tekstowy 80x25 znakow (czysty ekran)
	    mov	ah, 0h                      
	    int	10h
		
		call nl
		call nl
		call nl
		call nl
		call nl
		call nl
		
		mov dx, offset over				; komunikaty informujace o przegranej
		mov ah, 09h
		int 21h
		
		mov ax, word ptr ds:[score]
		dec ax
		mov cl, 100d
		div cl
		push ax
		add al, 48d
		mov dl, al
		mov ah, 02h
		int 21h
		
		pop ax
		mov al, ah
		mov ah, 0h
		mov cl, 10d
		div cl
		push ax
		add al, 48d
		mov dl, al
		mov ah, 02h
		int 21h
		
		pop ax
		mov al, ah
		add al, 48d
		mov dl, al
		mov ah, 02h
		int 21h
		
		call nl
		call nl
	
		mov dx, offset over2
		mov ah, 09h
		int 21h

		call nl
		call nl
		
		mov dx, offset over3
		mov ah, 09h
		int 21h
				
wait4user:								; czekaj, az uzytkownik zdecyduje, czy kontynuuje gre, czy wychodzi
		mov ah, 0h
		int 16h 
		
		cmp ah, 57d
		jz restart1
		
		cmp ah, 01h
		jz close2
		
		jmp wait4user
		
game1:	jmp game		
close1: mov	di,0						; stosw - slowo z ax do ES:DI
		mov	cx,(320*200)/2
		cld								; di bedzie inkrementowane
		mov	al, 0h
		mov	ah, al
		rep stosw

		mov	al, 3                       ; tryb tekstowy 80x25 znakow (czysty ekran)
	    mov	ah, 0h                      ; zmiana trybu VGA
	    int	10h
		
close2: mov	al, 3                       ; tryb tekstowy 80x25 znakow (czysty ekran)
	    mov	ah, 0h                      ; zmiana trybu VGA
	    int	10h

		mov	ah, 4ch     				; zakonczenie dzialania programu
		int	21h		
		
gotkey:	mov ah, 0h        				; w trakcie gry
		int 16h            	
		
		cmp ah, 1						; ESC - wyjście z gry
		jz close1
		
		cmp ah, 25d						; P - pauza
		jz paused
				
		cmp ah, 75d 					; ruch dolnej paletki w lewo
		jz left
		
		cmp ah, 77d						; ruch dolnej paletki w prawo
		jz right 
		
		cmp ah, 46d						; C - zmiana koloru pilki
		jz colo
		
		cmp ah, 13d						; zwiekszenie promienia pilki
		jz radpp
		
		cmp ah, 12d						; zmniejszenie promienia pilki
		jz radmm		
		
		jmp game						; kontynuuacja gry
				
paused:	mov ah, 0h        				; pauza - czekaj na dowolny klawisz
		int 16h 
		
		jmp game

radpp:	mov ah, byte ptr ds:[radius]
		cmp ah, 15d						; zwiekszanie promienia do maksymalnie 15
		jz game1
		
		add byte ptr ds:[radius], 01h
		jmp game
game2:	jmp game1		
radmm:	mov ah, byte ptr ds:[radius]
		cmp ah, 05h			; zmniejszanie promienia do minimalnie 5
		jz game1
		
		sub byte ptr ds:[radius], 01h
		jmp game
		
colo:	mov ah, byte ptr ds:[color]
		cmp ah, 11111111b		; zmiana koloru pilki
		jz zero
		
		add byte ptr ds:[color], 01h
		jmp game
zero:	mov byte ptr ds:[color], 0h
		jmp game
			
left:	mov ax, word ptr ds:[x]
		
		cmp ax, 0h						; czy przejscie w lewo wyprowadzi paletke poza ekran?
		jz game2

		call oneleft
					
		jmp game

right:	mov ax, word ptr ds:[x]					; czy przejscie w prawo wyprowadzi paletke poza ekran?
		
		cmp ax, 290d
		ja game2
		
		call oneright
	
		jmp game		
			
racket	proc							
		
		mov cx, 89d						; rakietka ma 3x30 pikseli

draw:	push cx
		
		mov ax, cx
		mov bh, 30d
		div bh
		
		xor cx, cx
		xor dx, dx
		
		mov cl, ah
		mov dl, al

		add cx, ds:[x]						; kolumna
		add dx, ds:[y]						; wiersz
		
		mov bh, 01h
		
		mov ah, 0Ch
		mov al, 14d							; kolor
		
		int 10h
		
		pop cx
		loop draw

		mov cx, word ptr ds:[x]						; kolumna
		mov dx, word ptr ds:[y]						; wiersz
		
		mov bh, 01h
		
		mov ah, 0Ch
		mov al, 14d							; kolor
		
		int 10h
		
		ret
racket	endp


oneleft proc								; przesuwanie paletki o jeden w lewo
		push cx
		mov cx, 03h
		
left_l:	push cx

		mov dx, cx
		add dx, word ptr ds:[y]				; wiersz
		dec dx
		
		mov cx, word ptr ds:[x]				; kolumna
		add cx, 29d

		mov bh, 01h
		
		mov al, 08h							; kolor
		mov ah, 0Ch
		
		int 10h
		
		pop cx
		push cx
		
		mov dx, cx
		add dx, word ptr ds:[y]				; wiersz
		dec dx
		
		mov cx, word ptr ds:[x]				; kolumna
		add cx, 30d

		mov bh, 01h
		
		mov al, 08h							; kolor
		mov ah, 0Ch
		
		int 10h
			
		pop cx
		push cx
		
		mov dx, cx
		add dx, word ptr ds:[y]				; wiersz
		dec dx
				
		mov cx, word ptr ds:[x]				; kolumna
		dec cx

		mov bh, 01h

		xor ax, ax		
		mov al, 14d							; kolor
		mov ah, 0Ch
		
		int 10h
		
		pop cx
		loop left_l
		
		sub word ptr ds:[x], 01h
		
		pop cx
		ret
oneleft endp
	
oneright proc								; paletka o jeden w prawo
		push cx
		mov cx, 03h
		
right_l:push cx

		mov dx, cx
		add dx, word ptr ds:[y]				; wiersz
		dec dx
		
		mov cx, word ptr ds:[x]				; kolumna

		mov bh, 01h
		
		mov ah, 0Ch
		mov al, 08h							; kolor
		
		int 10h
		
		pop cx
		push cx
		
		mov dx, cx
		add dx, word ptr ds:[y]				; wiersz
		dec dx
		
		mov cx, word ptr ds:[x]				; kolumna
		dec cx
		
		mov bh, 01h
		
		mov al, 08h							; kolor
		mov ah, 0Ch
		
		int 10h
	
		pop cx
		push cx
				
		mov dx, cx
		add dx, word ptr ds:[y]				; wiersz
		dec dx
		
		mov cx, word ptr ds:[x]				; kolumna
		add cx, 30d

		mov bh, 01h
		
		mov ah, 0Ch
		mov al, 14d							; kolor
		
		int 10h
		
		pop cx
		loop right_l
		
		add word ptr ds:[x], 01h
		
		pop cx
		ret
oneright endp
	
	
clear_b	proc

		mov	di, (320*3)						; stosw - slowo z ax do ES:DI
		mov	cx,(320*194)/2
		cld									; di bedzie inkrementowane
		mov	al, 08h
		mov	ah, al
		rep stosw

		ret
clear_b	endp	

drawing proc
		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		mov al, byte ptr ds:[O_y]
		sub dx, ax
		xor ax, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		mov al, byte ptr ds:[O_x]
		add cx, ax

		call pixel

		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		mov al, byte ptr ds:[O_x]
		sub dx, ax
		xor ax, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		mov al, byte ptr ds:[O_y]
		add cx, ax

		call pixel
	
		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		inc dx
		mov al, byte ptr ds:[O_y]
		add dx, ax
		xor ax, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		mov al, byte ptr ds:[O_x]
		add cx, ax
		
		call pixel
		
		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		inc dx
		mov al, byte ptr ds:[O_x]
		add dx, ax
		xor ax, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		mov al, byte ptr ds:[O_y]
		add cx, ax
		
		call pixel
		
		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		inc dx
		mov al, byte ptr ds:[O_y]
		add dx, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		dec cx
		mov al, byte ptr ds:[O_x]
		sub cx, ax

		call pixel
		
		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		inc dx
		mov al, byte ptr ds:[O_x]
		add dx, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		dec cx
		xor ax, ax
		mov al, byte ptr ds:[O_y]
		sub cx, ax
		
		call pixel

		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		mov al, byte ptr ds:[O_y]
		sub dx, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		dec cx
		xor ax, ax
		mov al, byte ptr ds:[O_x]
		sub cx, ax

		call pixel

		xor ax, ax
		mov dx, word ptr ds:[ball_y]			; wiersz
		mov al, byte ptr ds:[O_x]
		sub dx, ax
		mov cx, word ptr ds:[ball_x]			; kolumna
		dec cx
		xor ax, ax
		mov al, byte ptr ds:[O_y]
		sub cx, ax

		call pixel

		ret
drawing	endp


pixel	proc
		mov bh, 01h
		mov ah, 0Ch
		mov al, ds:[color]			; kolor
		int 10h 
		ret
pixel	endp
		
ball 	proc
		mov ax, ds:[go_down]
		cmp ax, 0h				; czy pilka porusza sie w dol?
		ja check_down
	
check_up:									; ruch pilki w dol
		xor ax, ax
		mov al, byte ptr ds:[radius]
		add ax, 02h

		mov bx, word ptr ds:[ball_y]
		cmp bx, ax
		jbe top_ball1
		
		jmp sides
		
check_down:									; skoro porusza sie w dol - czy jest juz na samym dole?
		mov ax, 196d
		sub al, byte ptr ds:[radius]
		
		mov bx, word ptr ds:[ball_y]
		cmp bx, ax
		jae end_ball2

sides:	mov ax, word ptr ds:[go_right]
		cmp ax, 00h				; czy porusza sie w prawo?
		jnz r_wall
		
		mov ax, word ptr ds:[left]
		cmp ax, 00h				; czy porusza sie w lewo?
		jnz l_wall
		
		jmp circle				
		
r_wall:	mov ax, word ptr ds:[ball_x]
		add al, byte ptr ds:[radius]
		
		cmp ax, 319d
		jb circle
		
		mov ax, word ptr ds:[go_right]		; odbicie od prawej sciany
		push ax
		mov ax, word ptr ds:[go_left]
		mov word ptr ds:[go_right], ax
		pop ax
		mov word ptr ds:[go_left], ax
		
		jmp fin2
		
l_wall:
		xor ax, ax
		mov al, byte ptr ds:[radius]

		cmp ax, word ptr ds:[ball_x]

		jb circle
		
		mov ax, word ptr ds:[go_right]		; odbicie od lewej sciany
		push ax
		mov ax, word ptr ds:[go_left]
		mov word ptr ds:[go_right], ax
		pop ax
		mov word ptr ds:[go_left], ax
		
		jmp fin2
top_ball1: jmp top_ball
end_ball2: jmp end_ball		
circle:	mov byte ptr ds:[O_y], 0h			; szukamy x-ów dla kolejnych wartosci y
				
draw_b:	mov al, byte ptr ds:[O_y]
		mov cl, byte ptr ds:[O_y]
		mul cl								; w ax mamy y^2
		push ax
		
		xor ax, ax
		mov cl, byte ptr ds:[radius]
		mov al, byte ptr ds:[radius]
		mul cl
		mov cx, ax
		
		pop ax
		
		sub cx, ax					; w cx mamy x^2
		
		mov bx, 0h					; szukamy najblizszego x
		
root:	xor ax, ax
		
		mov byte ptr ds:[O_x], bl

		mov al, bl
		mul bl						
		
		inc bl

		cmp ax, cx
		jb root									; dopóki ax<cx
		
		call drawing
		
		mov ah, byte ptr ds:[O_y]
		add byte ptr ds:[O_y], 01h							; dla kolejnych y
		
		mov al, byte ptr ds:[O_x]
		cmp al, ah
		ja draw_b
		
		jmp fin2
	
top_ball:										; pilka odbija sie od gory
		mov ax, word ptr ds:[go_up]				
		push ax									; korygujemy katy
		mov ax, word ptr ds:[go_down]
		mov word ptr ds:[go_up], ax
		pop ax
		mov word ptr ds:[go_down], ax
				 
		jmp fin2
	
end_ball:										; pilka odbija sie na dole
		mov ax, word ptr ds:[ball_x]
		xor bx, bx
		mov bl, byte ptr ds:[radius]
		sub ax, bx 
		dec ax
		mov bx, word ptr ds:[x]
		cmp bx, ax
		jna continue							; kat zalezny od tego, czy np. brzeg paletki
		
leftangle:										; kat 45 stopni (w lewo)
		mov ax, word ptr ds:[ball_x]
		xor bx, bx
		mov bl, byte ptr ds:[radius]
		add ax, bx

		mov bx, word ptr ds:[x]
		cmp bx, ax
		ja gameover		

		mov word ptr ds:[go_up], 02h
		mov word ptr ds:[go_down], 0h		
		mov word ptr ds:[go_right], 0h
		mov word ptr ds:[go_left], 02h
		
		jmp finpp
		
gameover:										; flaga przegranej
		mov byte ptr ds:[go], 01h
		
		jmp finpp
		
continue:mov ax, word ptr ds:[x]
		add ax, 14d
		mov bx, word ptr ds:[ball_x]
		
		cmp ax, bx
		jae leftangle2
				
		mov ax, word ptr ds:[ball_x]
		xor bx, bx
		mov bl, byte ptr ds:[radius]
		add ax, bx
		sub ax, 29d
		mov bx, word ptr ds:[x]
		cmp bx, ax
		jb rightangle
		
		mov ax, word ptr ds:[x]
		add ax, 17d
		mov bx, word ptr ds:[ball_x]
		cmp ax, bx
		jbe rightangle2		
				
		mov ax, word ptr ds:[go_up]
		push ax
		mov ax, word ptr ds:[go_down]
		mov word ptr ds:[go_up], ax
		pop ax
		mov word ptr ds:[go_down], ax
		
		jmp finpp

rightangle2:									; kat 30 stopni (w prawo)
		mov word ptr ds:[go_up], 02h
		mov word ptr ds:[go_down], 0h
		
		mov word ptr ds:[go_right], 01h
		mov word ptr ds:[go_left], 0h
		
		jmp finpp
			
leftangle2:										; kat 30 stopni (w lewo)
		mov word ptr ds:[go_up], 02h
		mov word ptr ds:[go_down], 0h
		
		mov word ptr ds:[go_right], 0h
		mov word ptr ds:[go_left], 01h
		
		jmp finpp
		
rightangle:										; kat 45 stopni (w prawo)
		mov ax, word ptr ds:[ball_x]
		xor bx, bx
		mov bl, byte ptr ds:[radius]
		sub ax, bx
		sub ax, 29d
		mov bx, word ptr ds:[x]
		cmp bx, ax
		jb gameover2
		
		mov word ptr ds:[go_up], 02h
		mov word ptr ds:[go_down], 0h
		
		mov word ptr ds:[go_right], 02h
		mov word ptr ds:[go_left], 0h
		
		jmp finpp
		
gameover2:										; flaga przegranej
		mov byte ptr ds:[go], 01h
		jmp fin2 
		
finpp:	add word ptr ds:[score], 01h							; wynik++			
		
		mov ax, word ptr ds:[score]						; co piec punktow, level up
		mov cl, 03h
		div cl
		
		cmp ah, 0h
		jnz fin2
		
		add byte ptr ds:[level], 01h
						
fin2:	ret
ball 	endp	
	
move	proc									; uaktualniamy wspolrzedne zaleznie od sciezki ruchu
		mov ax, word ptr ds:[go_down]
		add word ptr ds:[ball_y], ax
		
		mov ax, word ptr ds:[go_up]
		sub word ptr ds:[ball_y], ax
		
		mov ax, word ptr ds:[go_right]
		add word ptr ds:[ball_x], ax
		
		mov ax, word ptr ds:[go_left]
		sub word ptr ds:[ball_x], ax
		
		mov ax, word ptr ds:[x_top]
		add ax, 29d
		add ax, word ptr ds:[go_right]
		cmp ax, 320d
		ja nope
		
		mov ax, word ptr ds:[go_right]
		add word ptr ds:[x_top], ax
			
nope:	mov ax, word ptr ds:[x_top]
		mov bx, word ptr ds:[go_left]
		
		cmp ax, bx
		jb nope2
		
		mov ax, word ptr ds:[go_left]
		sub word ptr ds:[x_top], ax
			
nope2:	ret
move 	endp	
		
top_racket_move proc	
	
		mov ax, word ptr ds:[go_left]
		cmp ax, 0h
		ja top_racket_left
		
		mov ax, word ptr ds:[go_right]
		cmp ax, 0h
		ja top_racket_right
		
		jmp done2
		
top_racket_right:
				
		mov ax, word ptr ds:[y]
		push ax
		mov ax, word ptr ds:[x]
		push ax
		mov ax, word ptr ds:[x_top]
		push ax
		
		mov word ptr ds:[y], 0h
		
		mov ax, word ptr ds:[x_top]
		sub ax, word ptr ds:[go_right]
		mov word ptr ds:[x], ax
		
		mov cx, word ptr ds:[go_right]
		
top_racket_r:
		push cx
		
		call oneright
		
		pop cx
		loop top_racket_r
		
		jmp done
		
top_racket_left:
	
		mov ax, word ptr ds:[y]
		push ax
		mov ax, word ptr ds:[x]
		push ax
		mov ax, word ptr ds:[x_top]
		push ax
		
		mov word ptr ds:[y], 0h
		mov ax, word ptr ds:[x_top]
		add ax, word ptr ds:[go_left]
		mov word ptr ds:[x], ax
	
		mov cx, word ptr ds:[go_left]
		
top_racket_l:
		push cx
		
		call oneleft
		
		pop cx
		loop top_racket_l
				
done:	pop ax
		mov word ptr ds:[x_top], ax

		pop ax
		mov word ptr ds:[x], ax

		pop ax
		mov word ptr ds:[y], ax
		
done2: 	ret

top_racket_move endp
	
nl		proc

		mov dl, 10d
		mov ah, 02h
		int 21h
		
		mov dl, 13d
		mov ah, 02h
		int 21h

		ret
nl		endp	


tennis	proc

		mov ax, seg hello1            ; ustawiamy ds:dx na poczatek segmentu danych
		mov ds, ax
		
		mov dx, offset hello1
		mov ah, 09h
		int 21h
		
		call nl

		mov dx, offset hello2
		mov ah, 09h
		int 21h
		
		call nl
		
		mov dx, offset hello3
		mov ah, 09h
		int 21h
		
		call nl
		
		mov dx, offset hello4
		mov ah, 09h
		int 21h
		
		call nl
		
		mov dx, offset hello5
		mov ah, 09h
		int 21h
		
		call nl
		
		mov dx, offset hello6
		mov ah, 09h
		int 21h
		
		call nl
		
		mov dx, offset hello7
		mov ah, 09h
		int 21h
		
		call nl
	
		mov dx, offset hello8
		mov ah, 09h
		int 21h
		
		call nl
		
		mov dx, offset hello9
		mov ah, 09h
		int 21h
		
		call nl
		
		mov dx, offset hello10
		mov ah, 09h
		int 21h
		
		call nl
		
		ret
tennis	endp
	
	
code1 	ends
		
stack1	segment stack					
		dw 500 dup (?)
top1	dw ?
stack1 	ends

end 	start1