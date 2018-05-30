		assume cs:code1, ds:data1, ss:stack1
data1   segment
name1   db 255 dup (0)					; miejsce na nazwe pliku ASCIIZ
name2	db 255 dup ("$")				; miejsce na nazwe pliku jako string zakonczony $
hndl    dw ?							; miejsce na uchwyt pliku
string 	db 1840 dup (?)					; miejsce na tekst do wczytania/zapisu
m		db 80 dup ("_"), "$"			; tryb -m: poczatek stopki
m2		db "(  ,  )", "$"				; tryb -m: nawiasy na pozycje kursora
col		db 0h							; tryb -m: kolumna
line	db 0h							; tryb -m: linijka
hlp		db "help.txt0"					; nazwa pliku pomocy
msg1	db "Nie podales zadnych argumentow. Uzyj opcji -h, aby uzyskac pomoc.$"			; rozne komunikaty o bledach
msg2	db "Plik o podanej nazwie nie istnieje!$"
msg3	db "Wybrana opcja nie jest dostepna. Uzyj opcji -h, aby uzyskac pomoc.$"
msg4	db "Wystapil blad. Uzyj opcji -h, aby uzyskac pomoc.$"
msg5	db "Nazwa pliku jest zbyt dluga lub zawiera niedozwolone znaki. Uzyj opcji -h, aby uzyskac pomoc.$"
data1 	ends

code1   segment      
start1: mov ax, ds						; po uruchomieniu programu w DS znajduje sie adres PSP (Program Segment Prefix), w ktorym znajduja sie argumenty podane z wiersza polecen
		mov es, ax						; zapisujemy adres PSP w ES

		mov ax, seg [top1]     	        ; ustawiamy wskaznik i segment stosu
		mov ss, ax
		mov sp, offset [top1]
				
		mov ax, seg [name1]             ; ustawiamy ds:dx na poczatek segmentu danych
		mov ds, ax
		mov dx, offset [name1]
	    				
        mov ch, 0h						; w PSP pod adresem 80h znajduje sie jednobajtowa liczba informujaca o tym, ile znakow podano w linii komend
        mov cl, es:[080h]				; zapisujemy te liczbe w CX
		
		cmp cl, 0h						; sprawdzamy, czy podano argumenty
		jz noargs						; jesli nie - blad
        
		dec cl                          ; uaktualniamy  liczbe znakow argumentow podanych w wierszu polecen (pierwszy znak to spacja)
		mov si, 082h                    ; ustawiamy SI na poczatek argumentow
			
		mov ah, es:[082h]				; kopiujemy pierwszy znak (po spacji) do AH
		
		cmp ah, 2Dh						; czy pierwszy znak to "-"? (wywolanie fukcji z jedna z opcji)
		jz optns						; jesli pierwszy znak z parametrow wpisanych z linii komend przy uruchomieniu programu to "-", przejdz do etykiety optns
		
		cmp cl, 08h
		ja toolong
		
		call getnm						; jesli nie - uruchamiamy po prostu procedure getnm (get name)
		mov ds:[name2], "$"				; na poczatku name2, m i m2, ktore potrzebne sa w trybie ze stopka, umieszczamy znak $
		mov ds:[m], "$"					; ktory sprawi, ze funkcja 09h przerwania int 21h niczego nie wypisze
		mov ds:[m2], "$"
cont:	call check						; sprawdzamy, czy taki plik juz istnieje
		
		jnc opnfl
		
		call crtfl
		
		jc err							; jesli carry flag przyjmie wartosc 1 - wystapil blad przy tworzeniu pliku
	    mov hndl, ax
		
		jmp init

optns:  inc si
		mov ah, es:[si]
	
		cmp ah, 68h						; jesli program wywolano z opcja -h, przechodzimy do wypisania informacji pomocy
        jz help1
        
        cmp ah, 72h						; jesli program wywolano z opcja -r, pobieramy nazwe i przechodzimy do wyswietlenia pliku bez mozliwosci edycji
		jz rdonly
        
        cmp ah, 6Dh						; jesli program uruchomionio z opcja -m, przechodzimy do trybu ze stopka
        jz stats
        
        jmp wrng						; jesli probowabo uruchomic program z inna opcja - blad   
		
stats:	sub cl, 03h						; nazwa pliku jest o trzy znaki krotsza ("-m ")
		add si, 02h
		
		cmp cl, 08h
		ja toolong		
		call getnm
		
		jmp cont
		
opnfl:  call opn

init: 	mov bx, 0h						; jesli plik uruchomiono ze stopka, wypisujemy pozioma kreske w drugiej linijce od konca
		mov dh, 23d						; jesli nie, nic sie nie wypisze
		mov dl, 0h
		mov ah, 02h
		int 10h
		mov ax, seg m 					
		mov ds, ax
		mov dx, offset m				
		mov ah, 09h
		int 21h
		
		mov bx, 0h						; ustawiamy kursor w odpowiednim miejscu i wypisujemy nazwe pliku
		mov dh, 24d						; uzywajac funkcji 09h przerwania 21h
		mov dl, 0h						; oraz kopii nazwy zakonczonej znakiem $
		mov ah, 02h						; jesli plik uruchomiono bez stopki, nic sie nie wypisze
		int 10h		
		mov ax, seg name2 				
		mov ds, ax
		mov dx, offset name2
		mov ah, 09h
		int 21h
		
		mov bx, 0h						; w odpowiednim miejscu wypisujemy nawiasy, w ktorych umieszczona bedzie aktualna pozycja kursora
		mov dh, 24d						; jesli plik uruchomiono bez stopki nic sie nie wypisze
		mov dl, 72d
		mov ah, 02h
		int 10h
		mov ax, seg m2					
		mov ds, ax
		mov dx, offset m2
		mov ah, 09h
		int 21h			
		
		mov dx, 0h
		mov bx, 0h
		mov ah, 02h
		int 10h
		
edit:   call footr

		mov ah, 0h                    	; oczekiwanie na wcisniecie klawisza
        int 16h   
	    	
        push ax
        
		call ctrl						; czy wcisniety jest ctrl?
        jz outpt						; jesli nie, to przechodzimy do pisania
		
ctrlopt:pop ax 							; jesli tak, to sprawdzamy, czy rownoczesnie wcisniete s (save) lub x (close)
        
	    cmp ah, 45d
	    jz close1
		
		cmp ah, 31d
	    jz save 
	    
	    jmp edit
	    						
outpt:  pop ax

		cmp ah, 15d						; tabulator (z ostroznosci na koniec linijki)
		jz tabs
		cmp ah, 14d                     ; backspace
        jz bs     
        cmp ah, 72d                     ; up
        jz up 
        cmp ah, 75d                     ; left
        jz left
        cmp ah, 77d                     ; right
        jz right
        cmp ah, 80d                     ; down
        jz down                                        
		cmp ah, 28d
		jz ent
		
		push ax							; nie jest wcisniety zaden wyjatkowy klawisz - nalezy postepowac normalnie
		
		call updloc
			
		cmp dl, 79d						; czy jestesmy w ostatniej kolumnie?
		jnz mid							; jak nie, to wypisujemy normalnie
		
		cmp dh, 22d						; jak tak, to sprawdzamy, czy jestesmy tez w ostatniej linijce
		jz last							; jesli jestesmy na samym koncu dokumentu, to nie mozamy pisac dalej

mid:	pop ax							; normalnie wypisujemy jeden znak
		mov dl, al
        mov ah, 02h
	    int 21h
	 		
		jmp edit
	
last:	pop ax							; wypisujemy ostatni znak w prawym dolnym rogu i wracamy kursorem - dalsze pisanie nie jest mozliwe
		mov dl, al
        mov ah, 02h
	    int 21h
		
		mov dh, 22d
		mov dl, 79d
		mov bx, 0h
		mov ah, 02h
		int 10h
		
		jmp edit
		
bs:     call bs_p
		jmp edit
		
tabs:	call tabs_p
		jmp edit
		
up:		call up_p
		jmp edit

left:	call left_p
		jmp edit
		
right:	call right_p
		jmp edit
		
down:	call down_p
		jmp edit

ent:	call ent_p
		jmp edit
			
help1:	mov bx, 0h						; dokument pomocy
		mov si, offset hlp				; nazwa pliku tekstowego help
		
h_loop:	lodsb							; laduje bajt z DS:SI do rejestru AL
		mov ds:[name1+bx], al			; przenosi ten bajt do wskazanego miejsca w pamieci
		inc bx
		cmp al, "0"
		jnz h_loop						; powtarza, dopoki cala nazwa nie zostanie skopiowana w miejsce przewidziane dla nazwy pliku do otwarcia
		
		call opn						; otworzenie i wypisanie pliku

		mov ah, 01h						; funkcja odpowiedzialna za ksztalt kursora
		mov ch, 00100000b				; bit 5 - kursor niewidoczny
		mov cl, 0h						
		int 10h		

key2:	mov ah, 0h                      ; oczekiwanie na wcisniecie klawisza
        int 16h   
	    	
        cmp ah, 45d						; czy wcisnieto x?
	    jnz key2						; jesli nie - nie nalezy nic robic
        		
		mov ah, 02h                     ; jesli tak, to czy x+ctrl?
        int 16h       
		
        and al, 00000100b				; bit 2: ctrl
        jz key2 

		jmp close1						; jesli ctrl+x, zamknij dokument pomocy
		
rdonly:	sub cl, 03h						; nazwa pliku jest o trzy znaki krotsza ("-r ")
		add si, 02h
		
		cmp cl, 08h
		ja toolong
		
		call getnm						; odczytaj nazwe
		
		call check						; sprawdz, czy istnieje 		  				

		jc dsntex
		
		call opn						; otworz i wypisz plik
		
		mov ah, 01h						; niewidoczny kursor
		mov ch, 00100000b
		mov cl, 0h
		int 10h
		
key:	mov ah, 0h                      ; oczekiwanie na wcisniecie klawisza
        int 16h   
	    	
        cmp ah, 45d						; czy x?
	    jnz key
        		
		mov ah, 02h                     ; czy ctrl?
        int 16h       
        and al, 00000100b
        jz key 

		jmp close1						; jesli ctrl+x, zamknij
	    
noargs:	mov dx, offset msg1				; obsluga bledow: wywolanie programu bez argumentow
		mov ah, 09h         			; stosujemy funkcje 9h przerwania 21h, aby wypisac string z ds:dx
		int 21h             			; (wypisywanie zakonczy sie na znaku "$")
		
		jmp close2
		
err:	mov dx, offset msg4				; obsluga bledow: inne bledy
		mov ah, 09h         			; stosujemy funkcje 9h przerwania 21h, aby wypisac string z ds:dx
		int 21h
		jmp close2
			
dsntex:	mov ax, seg msg2				; obsluga bledow: plik wybrany do otworzenia w trybie do odczytu nie istnieje
		mov ds, ax
		mov dx, offset msg2			
		mov ah, 09h         			; stosujemy funkcje 9h przerwania 21h, aby wypisac string z ds:dx
		int 21h             			; (wypisywanie zakonczy sie na znaku "$")
		
		jmp close2
		
wrng: 	mov ax, seg msg3				; obsluga bledow: wybrana funkcja nie jest dostepna
		mov ds, ax
		mov dx, offset msg3			
		mov ah, 09h         			; stosujemy funkcje 9h przerwania 21h, aby wypisac string z ds:dx
		int 21h             			; (wypisywanie zakonczy sie na znaku "$")
		
		jmp close2		

toolong:mov dx, offset msg5			; obsluga bledow: wywolanie programu bez argumentow
		mov ah, 09h         			; stosujemy funkcje 9h przerwania 21h, aby wypisac string z ds:dx
		int 21h             			; (wypisywanie zakonczy sie na znaku "$")
		
		jmp close2
		
		
		
save:	call updloc
	
		mov col, dl
		mov line, dh
		
		mov si, 0h
		
cursor: mov ax, si
		mov ch, 0h
		mov cl, 80d
		div cl							; ax/cx = cx * al + ah
		
		mov dh, al
		mov dl, ah
		
		mov bx, 0h						; zaczynajac od (0,0) idziemy po kolejnych komorkach i wierszach
		mov ah, 02h
		int 10h
				
		mov ax, seg string
		mov es, ax
		mov ds, ax
		mov di, offset string
		add di, si

		mov ah, 08h						; przeczytaj znak spod kursora i zapisz w al
		mov bx, 0h
		int 10h
		
		stosb 							; z AL pod adres ES:DI
		
		inc si
		cmp si, 1840d					; jesli nie zapisano jeszcze 80x23 znakow, kontynuuj
		jb cursor
		
		mov dx, offset [name1]      	; po zakonczeniu petli, utworz plik o podanej nazwie (nadpisanie pliku)
		xor cx, cx
        mov ah, 3Ch
		int 21h
		
		jc err							; jesli carry flag przyjmie wartosc 1 - wystapil blad przy tworzeniu pliku
	    
		mov hndl, ax					; zaktualizuj uchwyt

		mov ah, 40h						; zapisz 1840 bajtow ze stringa do pliku
		mov bx, hndl
		mov cx, 1840d
		mov dx, offset string
		int 21h
		
		jc err
						
		mov dh, line					; wroc kursorem do wyjsciowej pozycji - mozliwa jest dalsza edycja
		mov dl, col
		mov ah, 02h
		mov bx, 0h
		int 10h
		
		jmp edit

close1: mov	al, 3                       ; tryb tekstowy 80x25 znakow (czysty ekran)
	    mov	ah, 0h                      ; zmiana trybu VGA
	    int	10h
		
close2: mov	ah, 4ch     				; zakonczenie dzialania programu
		int	21h

getnm	proc							; w SI mamy adres poczatku danych z linii komend, a w CX liczbe znakow
		mov bx, 0
loop1:  mov al, es:[si+bx]              ; w petli pobieramy kolejne znaki z argumentow podanych z wiersza polecen
		
		mov ds:[name1+bx], al
		mov ds:[name2+bx], al
        inc bx
        loop loop1
   
		mov byte ptr [name1+bx], "0"    ; nazwe pliku konczymy zerem (standard ASCIIZ)
		mov byte ptr [name2+bx], "$"	; w drugim wariancie konczymy ja znakiem $, co ulatwi nam wypisanie jej w trybie ze stopka
	    
		ret
getnm 	endp

opn		proc							
		mov dx, offset [name1]          ; otwieranie pliku
        mov ah, 3Dh
        int 21h
		
		jc err							; jesli carry flag przyjmie wartosc 1 - wystapil blad przy otwieraniu pliku
	    mov hndl, ax					; kopiujemy uchwyt pliku
		
	    mov	al, 3                       ; tryb tekstowy 80x25 znakow
	    mov	ah, 0h                      ; zmiana trybu VGA
	    int	10h
		
		mov dx, 0h						; ustawiamy kursor na poczatku
		mov bx, 0h
		mov ah, 02h
		int 10h

		mov ah, 3Fh						; kopiujemy 80x23 znaki (ostatnie dwie linijki sa wylaczone z uzycia ze wzgledu na stopke)
		mov bx, hndl
		mov cx, 1840d
		mov dx, offset string
		int 21h
		jc err							; ustawione carry flag oznaczaloby wystapienie bledu
			
		mov si, 0h
		mov di, 0h		
		
letters:cmp si, 1840d					; wypisujemy litery pojedynczo - przy wypisywaniu calego stringa na raz wystepowal problem z klawiszem enter i przewijaniem ekranu
		jz fin							; uniemozliwialo to otworzenie chociazby plikow utworzonych w Notatniku
		
		mov dl, ds:[string+di]			; kopiujemy kolejne znaki i sprawdzamy, czy sa enterem
		inc si
		inc di
		cmp dl, 0Ah
		jnz not_ent
		
		mov bx, 0h						; jesli tak, to oprocz line feed i carriage return, aktualizujemy liczbe znakow do wypisania
		mov ah, 03h						; "wyspacjowana" reszta linijki
		int 10h
		
		cmp dh, 22d						; na wszelki wypadek sprawdzamy, czy doszlismy juz do ostatniej linijki
		jz fin
		
		mov dh, 0h						; korygujemy liczbe znakow do wypisania o reszte linijki, w ktorej wcisnieto enter
		add si, 80d
		sub si, dx

		mov dl, 0Ah						; carriage return i line feed
		mov ah, 02h
		int 21h
		
		mov dl, 0Dh
		
not_ent:mov ah, 02h						; jesli znak skopiowany do DL nie jest znakiem line feed, wypisujemy go normalnie
		int 21h
		jmp letters						; kontynuujemy wypisywanie, az wypisze sie 1840 znakow
		
fin:	mov dx, 0h						; wracamy kursorem na poczatek pliku
		mov bx, 0h
		mov ah, 02h
		int 10h

		ret
opn		endp

check	proc
		mov dx, offset name1 		    ; adres nazwy pliku
		mov cx, 0h						; maska - chcemy znalezc zwykly plik
		mov ah, 4Eh 		   			; funkcja 4Eh znajduje pierwszy plik o podanej nazwie 
		int 21h
		ret
check 	endp

updloc	proc							; uaktualnienie obecnej pozycji kursora
		mov bx, 0h						; dh - wiersz, dl - kolumna
		mov ah, 03h
		int 10h
		ret
updloc	endp

footr 	proc

		cmp ds:[name2], "$"				; sprawdzamy, czy na poczatek nazwy pliku w formacie kompatybilnym z funkcja 09h przerwania int 21h znajduje sie znak $
		jz not_m						; jesli tak - wypisywanie stopki nie jest konieczne

		call updloc						; w przeciwnym wypadku sprawdzamy pozycje kursora
		mov col, dl
		mov line, dh
			
		mov bx, 0h						; ustawiamy kursor w odpowiednim miejscu
		mov dh, 24d
		mov dl, 73d
		mov ah, 02h
		int 10h

		mov ah, 0h						; numer kolumny dzielimy przez 10, aby rozbic go na cyfry i wypisac
		mov al, line
		mov cl, 0Ah
		div cl
		
		push ax
		
		mov dl, al						; wypisujemy pierwsza cyfre
		add dl, 30h
		mov ah, 02h
		int 21h
			
		pop ax
		
		mov dl, ah						; wypisujemy druga cyfre
		add dl, 30h
		mov ah, 02h
		int 21h		
		
		mov bx, 0h						; ustawiamy odpowiednio kursor
		mov dh, 24d
		mov dl, 76d
		mov ah, 02h
		int 10h
		
		mov ah, 0h						; numer linijki dzielimy na 10, aby rozbic go na cyfry i wypisac
		mov al, col
		mov cl, 0Ah
		div cl
	
		push ax
	
		mov dl, al						; wypisujemy pierwsza cyfre
		add dl, 30h
		mov ah, 02h
		int 21h

		pop ax

		mov dl, ah						; wypisujemy druga cyfre
		add dl, 30h
		mov ah, 02h
		int 21h	
		
		mov bx, 0h						; wracamy kursorem do aktualnej pozycji
		mov dh, line
		mov dl, col
		mov ah, 02h
		int 10h
		
not_m:	ret
footr	endp
		
ctrl	proc
		mov ah, 02h                     ; czy ctrl jest wcisniety?
        int 16h       
        and al, 00000100b
		ret
ctrl	endp

up_p proc
		call updloc
		cmp dh, 0h						; czy jestesmy w pierwszej linijce?
		jz end_up						; jesli nie, przejdz do linijki wyzej
		sub dh, 01h
		mov ah, 02h
		int 10h
end_up:	ret
up_p endp

left_p	proc
		call updloc
		cmp dl, 0h						; czy jestesmy w pierwszej kolumnie?
		jnz ok
		cmp dh, 0h						; jesli tak - sprawdz, czy jestesmy tez w pierwszej linijce
		jz end_l						; wtedy <- nie jest mozliwe
		sub dh, 01h						; w przeciwnym wypadku przejdz na koniec poprzedniej linijki
		mov dl, 79d
		mov ah, 02h
		int 10h
		jmp end_l
ok:		sub dl, 01h						; lub - jesli nie jestesmy w pierwszej kolumnie - po prostu o jeden w lewo
		mov ah, 02h
		int 10h
end_l:	ret
left_p	endp

right_p	proc
		call updloc
		cmp dl, 79d						; jesli jestesmy w ostatniej kolumnie i wierszu, -> nie jest mozliwe
		jz nl
		inc dl							; jesli nie jestesmy w ostatniej kolumnie, po prostu przejdz o jeden w prawo
		mov ah, 02h
		int 10h
		jmp end_r
nl:		cmp dh, 22d						; jesli jestesmy na koncu wiersza, ale nie w ostatniej kolumnie, konieczne jest przejscie na poczatek kolejnej linijki
		jz end_r
		inc dh
		mov dl, 0h
		mov ah, 02h
		int 10h
end_r:	ret
right_p	endp

down_p	proc
		call updloc										
		cmp dh, 22d						; czy jestesmy w ostatniej linijce?
		jz end_d
		inc dh
		mov ah, 02h						; jesli nie, przejdz do wiersza nizej
		int 10h
end_d:	ret
down_p	endp

ent_p	proc	
		call updloc
		cmp dh, 22d						; czy jestesmy w ostatniej linijce?
		jz end_ent
		
		mov dl, 0Ah						
        mov ah, 02h
	    int 21h

end_ent:ret	
ent_p 	endp

tabs_p	proc
		call updloc

		cmp dh, 22d
		jnz ok
				
		cmp dl, 71d						; aby nie wyjsc poza obszar edytora
		ja end_t 
		
ok:		mov dl, 09h
        mov ah, 02h
	    int 21h
		jmp end_t
end_t:	ret
tabs_p	endp

crtfl 	proc							; tworzenie pliku
		mov dx, offset [name1]      	; jesli nie istnieje - nalezy go stworzyc
		xor cx, cx
        mov ah, 3Ch
		int 21h
		
		mov	al, 03h                     ; tryb tekstowy 80x25 znakow
	    mov	ah, 0h                      ; zmiana trybu VGA
	    int	10h
		ret
crtfl 	endp

bs_p	proc							; backspace
		call updloc
		
		cmp dl, 0h
		jnz ok_b
		cmp dh, 0h
		jz end_b						; niemozliwe w (0,0)
		
ok_b:	call left_p
		
		mov dl, 20h
        mov ah, 02h
	    int 21h

		call left_p
		
end_b:	ret
bs_p	endp


code1 ends
		
stack1	segment stack					; miejsce na stos (100 slow)
		dw 255 dup (?)
top1	dw ?
stack1 ends

end start1