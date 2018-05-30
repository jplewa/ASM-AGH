		assume cs:code1, ds:data1, ss:stack1
data1   segment
welcome	db "Podaj cyfre w systemie szestnastkowym: $"  
er		db "Podany znak nie jest cyfra szesnastkowa!$"
zero    db "$  ###$ #   #$#     #$#     #$#     #$ #   #$  ###$"
one     db "$   #$  ##$ # #$   #$   #$   #$ #####$" 
hexn 	db ? 
cursor  db 0h                           ; zmienna informujaca nas o przesunieciu wypisania kolejnych banerowych cyfr 
n       db 0h							; zmienna informujaca nas o tym, ile znakow z danego stringa wypisano
data1 	ends

code1   segment      
start1: mov ax, seg [top1]     	        ; ustawiamy wskaznik i segment stosu
		mov ss, ax
		mov sp, offset [top1]
				
		mov ax, seg [welcome]           ; ustawiamy ds:dx na segment i offset prosby o wpisanie cyfry
		mov ds, ax
		mov dx, offset [welcome]
				
		mov ah, 09h                     ; stosujemy funkcje 9h przerwania 21h, aby wypisac string z ds:dx
		int 21h                         ; (wypisywanie zakonczy sie na znaku "$")
		
		mov ah, 01h                     ; wczytujemy wpisany z klawiatury znak do rejestru al (z echem)
		int 21h                         ; stosujac funkcje 01h przerwania 21h
				
		mov byte ptr [hexn], al	        ; zapisujemy podany znak jako zmienna hexn 
		       							
		mov dl, 10d                     ; przechodzimy dwie linijki nizej
	    mov ah, 02h                     ; stosujac funkcje 02h przerwania 21h oraz znak "line feed" o kodzie ASCII 10d
		int 21h  
			
		mov dl, 13d        				; przesuwamy sie na poczatek linijki
	    mov ah, 02h         			; stosujac funkcje 02h przerwania 21h oraz znak "carriage return" o kodzie ASCII 13d
	    int 21h				
		
	    cmp [hexn], 2Fh	    			; jesli kod ASCII wpisanego znaku jest mniejszy lub rowny 2Fh, to nie jest on ani cyfra dziesietna, ani litera z zakresu A-F
		jbe incrct       			    ; przeskakujemy do miejsca, w ktorym wypisze sie stosowny komunikat
		
		cmp [hexn], 39h					; jesli kod ASCII wpisanego znaku jest wiekszy od 2Fh i mniejszy lub rowny 39h,to jest on cyfra dziesietna
		jbe number						; przeskakujemy do miejsca, w ktorym skorygujemy odpowiednio przesuniecie kodu ASCII

	    cmp [hexn], 40h					; jesli kod ASCII wpisanego znaku jest wiekszy od 39h i mniejszy lub rowny 40h, to nie jest on ani cyfra dziesietma, ani litera z zakresu A-F
        jbe incrct						; przeskakujemy do miejsca, w ktorym wypisze sie stosowny komunikat 
        
        cmp [hexn], 46h     			; jesli kod ASCII wpisanego znaku jest wiekszy od 40h i mniejszy lub rowny 46h, to jest on litera z zakresu A-F
	    jbe cptl            			; przeskakujemy do miejsca, w ktorym skorygujemy odpowiednio przesuniecie kodu ASCII
        
        cmp [hexn], 60h     			; jesli kod ASCII wpisanego znaku jest wiekszy od 46h i mniejszy lub rowny 60 h, to nie jest on ani cyfra dziesietna, ani litera z zakresu A-F
	    jbe incrct          			; przeskakujemy do miejsca, w ktorym wypisze sie stosowny komunikat
        
        cmp [hexn], 66h     			; jesli kod ASCII wpisanego znaku jest wiekszy od 60h i mniejszy lub rowny 66h, to jest on mala litera z zakresu a-f
	    jbe lwrcs           			; przeskakujemy do miejsca, w ktorym skorygujemy odpowiednio przesuniecie kodu ASCII 
										; w przeciwnym wypadku, kod ASCII tego znaku musi byc wiekszy od 67H, co oznacza, ze nie jest cyfra szesnastkowa (kontynuujemy do incrct)
incrct:	mov dl, 10d                     ; przechodzimy do linijki nizej
	    mov ah, 02h                     ; stosujac funkcje 02h przerwania 21h oraz znak "line feed" o kodzie ASCII 10d
		int 21h  
					
		mov dl, 13d        				; przesuwamy sie na poczatek linijki
	    mov ah, 02h	        			; stosujac funkcje 02h przerwania 21h oraz znak "carriage return" o kodzie ASCII 13d
	    int 21h
		
		mov ax, seg [er]    		    ; wypisujemy komunikat o blednym znaku za pomoca przerwania 21h
		mov ds, ax
		mov dx, offset [er]
				
		mov ah, 09h
		int 21h
		
		jmp ending_incrct          		; przeskakujemy do miejsca, w ktorym zakonczy sie dzialanie programu (dla wprowadzonej niepoprawnej wartosci)
		
cptl: 	sub [hexn], 37h     			; przesuwamy wartosc o 37h, aby z kodu ASCII cyfry szesnastkowej (wyrazonej litera z zakresu A-F) uzyskac cyfre szesnastkowa
        jmp correct         			; przeskakujemy do miejsca, gdzie wykonywane sa dalsze kroki z poprawna wartoscia zapisana w zmiennej hexp

lwrcs: 	sub [hexn], 57h     			; przesuwamy wartosc o 57h, aby z kodu ASCII cyfry szesnastkowej (wyrazonej litera z zakresu a-f) uzyskac cyfre szesnastkowa
 		jmp correct         			; przeskakujemy do miejsca, gdzie wykonywane sa dalsze kroki z poprawna wartoscia zapisana w zmiennej hexp
 		
number: sub [hexn], 30h     			; przesuwamy wartosc o 30h, aby z kodu ASCII cyfry szesnastkowej (wyrazonej cyfra dziesietna) uzyskac cyfre szesnastkowa
	
correct:
		; opcjonalny fragment kodu, ktory umozliwi wypisywanie z dowolnym wcieciem
		; mov dl, 10d                   ; przechodzimy do linijki nizej
	    ; mov ah, 02h                   ; stosujac funkcje 02h przerwania 21h oraz znak "line feed" o kodzie ASCII 10d
		; int 21h  

		; mov ah, 03h        			; funkcja 3h przerwania 10h
	    ; int 10h						; gdzie jestesmy? dh - wiersz, dl - kolumna
			
        ; mov dl, [cursor]   		 	; przesun sie do kolumny, w ktorej zaczyna sie dana cyfra (zachowujemy numer wiersza zmodyfikowant przez funkcje 02h przerwania 21h)
		; mov ah, 02h
	    ; int 10h      		       		; przenosimy sie do zmienionych wspolrzednych dh, dl
        
		mov cl, 04h	    				; zaczynamy operacje na skorygowanej wartosci
	    shl [hexn], cl      			; przesuwamy wartosc o cztery bity w lewo, zeby bity, na ktorych nam zalezy, byly najstarsze
       		
        mov cx, 04h				        ; ustawiamy cx na potrzebna liczbe przebiegow petli loop1, czyli 4
		
loop1:	push cx   	        			; zapisujemy licznik przebiegu glownej petli na stosie
        rol [hexn], 01h       			; rotujemy nasza (juz przesunieta) binarna liczbe o 1, co sprawia, ze wszystkie cyfry przesuwaja sie w lewo,
										; a pierwsza cyfra laduje na koncu oraz carry flag przyjmuje jej wartosc
		mov byte ptr [n], 0h   		    ; zerujemy n, w ktorym  przechowywalismy przesuniecie w wypisywaniu stringa								
        jc  oneout          			; jesli wartosc CF wynosi 1, przenosimy sie do oneout, ktore wypisze nam jedynke
	    jnc  zeroout        			; jesli wartosc CF wynosi 0, przenosimy sie do zeroout, ktore wypisze nam zero		
back:   								; do tego miejsca wracamy po wypisaniu banerowej cyfry
        pop cx            				; zdejmujemy licznik przebiegu glownej petli ze stosu
loop loop1       	            		; powtarzamy dzialanie petli, za kazdym razem wartosc cx sie dekrementuje 
		jmp ending_crct	    			; po wypisaniu czterech znakow i zakonczeniu petli loop1, przechodzimy na koniec programu
oneout:									; wypisywanie jedynki
	    mov cx, 07h           			; licznik petli wypisujacej cyfre linijka po linijce ustawiamy na 7 (liczba linijek)      
oloop: 	push cx             			; odkladamy cx (przebiegi wewnetrznej petli) na stos, poniewaz int 10h zmieni wartosc tego rejestru
																		
		mov ah, 03h        				; funkcja 3h przerwania 10h
	    int 10h							; gdzie jestesmy? dh - wiersz, dl - kolumna
		
		mov al, dl
		mov ah, 0h
	    push ax   		          		; odkladamy numer kolumny, w ktorej obecnie sie znajdujemy, na stos
										; jest nam to potrzebne, aby wypisac potem odpowiedni fragment stringa, poniewaz liczba znakow jest rozna zaleznie od linijki       	 	

		mov dl, 10d                     ; przechodzimy do linijki nizej
	    mov ah, 02h                     ; stosujac funkcje 02h przerwania 21h oraz znak "line feed" o kodzie ASCII 10d
		int 21h  
			
		mov ah, 03h        				; funkcja 3h przerwania 10h
	    int 10h							; gdzie jestesmy? dh - wiersz, dl - kolumna
			
        mov dl, byte ptr [cursor]   	; przesun sie do kolumny, w ktorej zaczyna sie dana cyfra (zachowujemy numer wiersza zmodyfikowant przez funkcje 02h przerwania 21h)
		mov ah, 02h
	    int 10h      		       		; przenosimy sie do zmienionych wspolrzednych dh, dl
        
		pop ax              			; sciagamy stary numer kolumny ze stosu
	    mov ah, 0h
		sub al, byte ptr [cursor]		; odejmujemy od niego numer kolumny, w ktorej zaczyna sie wypisywana cyfra
        add al, 01h         			; korygujemy o 1 (znaki $)
										; upewniamy sie, ze cale dx ma potrzebna nam wartosc (liczba znakow, ktore wlasnie wypisalismy)
        		    
        add al, [n]        				; dodajemy n (dotychczasowo wypisana liczba znakow z naszego stringa)
	    mov byte ptr [n], al			; zapisujemy sobie dotychczasowe przesuniecie w zmiennej n
		mov dx, offset [one] 			; do tego przesuniecia wzgledem poczatku dodajemy offset
		add dl, al
		
		mov ax, seg [one]   			; ustawiamy ds:dx na segment i offset prosby o wpisanie cyfry
		mov ds, ax
		
		mov ah, 09h						; wypisujemy fragment stringa zero, zaadresowany przez DS:DX
		int 21h    						; za pomoca funkcji 9 przerwania 21h
		pop cx							; sciagamy licznik petli ze stosu
				
loop oloop		               			; powtarzamy, aby wypisac kolejne linijki skladajace sie na banerowa cyfre
										; po wyjsciu z petli (czyli wypisaniu siedmiu linijek)        
        add [cursor], 08h   			; zwiekszamy cursor (odpowiedzialny za umiejscowienie kolejnych banerowych cyfr) o 8
		
		mov ah, 03h        				; funkcja 3h przerwania 10h
	    int 10h							; gdzie jestesmy? dh - wiersz, dl - kolumna
		
		sub dh, 07h		     			; przenosimy sie do poczatkowej linijki
		mov dl, byte ptr [cursor]   	; jako kolumne ustawiamy wartosc zmiennej cursor, ktora jest zalezna od tego, ile cyfr juz wypisano

		mov ah, 02h
	    int 10h             			; przenosimy sie do zmienionych wspolrzednych dh, dl (funkcja 2 przerwania 10h)
                             
        jmp back  				        ; wracamy do glownej petli, aby wypisac kolejna banerowa cyfre lub zakonczyc dzialanie programu       
		
zeroout:								; wypisywanie zera
	    mov cx, 07h				        ; licznik petli wypisujacej cyfre linijka po linijce ustawiamy na 7 (liczba linijek)
zloop:  push cx             			; odkladamy cx (przebiegi wewnetrznej petli) na stos, poniewaz int 10h zmieni wartosc tego rejestru

		mov ah, 03h        				; funkcja 3h przerwania 10h
	    int 10h							; gdzie jestesmy? dh - wiersz, dl - kolumna
		
		mov al, dl
		mov ah, 0h
	    push ax   		          		; odkladamy numer kolumny, w ktorej obecnie sie znajdujemy, na stos
										; jest nam to potrzebne, aby wypisac potem odpowiedni fragment stringa, poniewaz liczba znakow jest rozna zaleznie od linijki       	 	
		mov dl, 10d                     ; przechodzimy do linijki nizej
	    mov ah, 02h                     ; stosujac funkcje 02h przerwania 21h oraz znak "line feed" o kodzie ASCII 10d (0Ah)
		int 21h  
			
		mov ah, 03h        				; funkcja 3h przerwania 10h
	    int 10h							; gdzie jestesmy? dh - wiersz, dl - kolumna
			
        mov dl, byte ptr [cursor]  		; przesun sie do kolumny, w ktorej zaczyna sie dana cyfra
		mov ah, 02h
	    int 10h      		       		; przenosimy sie do zmienionych wspolrzednych dh, dl
        
		pop ax              			; sciagamy stary numer kolumny ze stosu
	    mov ah, 0h
		sub al, byte ptr [cursor]		; odejmujemy od niego numer kolumny, w ktorej zaczyna sie wypisywana cyfra
        add al, 01h         			; korygujemy o 1 (znaki $)
										; upewniamy sie, ze cale dx ma potrzebna nam wartosc (liczba znakow, ktore wlasnie wypisalismy)
        		    
        add al, [n]        				; dodajemy n (dotychczasowo wypisana liczba znakow z naszego stringa)
	    mov byte ptr [n], al			; zapisujemy sobie dotychczasowe przesuniecie w zmiennej n
		mov dx, offset [zero] 			; do tego przesuniecia wzgledem poczatku dodajemy offset
		add dl, al
		
		mov ax, seg [zero]              ; ustawiamy ds:dx na segment i offset prosby o wpisanie cyfry
		mov ds, ax
		
		mov ah, 09h						; wypisujemy fragment stringa zero, zaadresowany przez DS:DX
		int 21h    						; za pomoca funkcji 9 przerwania 21h
	
		pop cx							; sciagamy licznik petli ze stosu

loop zloop								; powtarzamy, aby wypisac kolejne linijki skladajace sie na banerowa cyfre
										; po wyjsciu z petli (czyli wypisaniu siedmiu linijek)        
		add [cursor], 08h   			; zwiekszamy cursor (odpowiedzialny za umiejscowienie kolejnych banerowych cyfr) o 8
		
		mov ah, 03h        				; funkcja 3h przerwania 10h
	    int 10h							; gdzie jestesmy? dh - wiersz, dl - kolumna	

		sub dh, 07h		     			; przenosimy sie do poczatkowej linijki
		mov dl, byte ptr [cursor]   	; jako kolumne ustawiamy wartosc zmiennej cursor, ktora jest zalezna od tego, ile cyfr juz wypisano

		mov ah, 02h
	    int 10h             			; przenosimy sie do zmienionych wspolrzednych dh, dl (funkcja 2 przerwania 10h)
                             
        jmp back  				        ; wracamy do glownej petli, aby wypisac kolejna banerowa cyfre lub zakonczyc dzialanie programu       

ending_crct: 
		mov cx, 08h						; ponieważ po wypisaniu każdej banerowej cyfry wracamy do początkowej linijki, konieczne jest przeniesienie sie o 8 linijek nizej (1 linijka odstepu)
scroll:
		mov dl, 10d                     ; przechodzimy do linijki nizej
	    mov ah, 02h                     ; stosujac funkcje 02h przerwania 21h oraz znak "line feed" o kodzie ASCII 10d
		int 21h  
loop scroll
					
		mov dl, 0Dh        				; przesuwamy sie na poczatek linijki
	    mov ah, 02h         			; stosujac funkcje 02h przerwania 21h oraz znak "carriage return" o kodzie ASCII 13d (0Dh)
	    int 21h
		
        mov ah, 0h						; oczekujemy na nacisniecie dowolnego klawisza
	    int 16h  
             
        mov	ah, 4ch     				; zakonczenie dzialania programu
		int	21h
		
ending_incrct: 

		mov dl, 10d                     ; przechodzimy do linijki nizej
	    mov ah, 02h                     ; stosujac funkcje 02h przerwania 21h oraz znak "line feed" o kodzie ASCII 10d
		int 21h  
					
		mov dl, 13d        				; przesuwamy sie na poczatek linijki
	    mov ah, 02h         			; stosujac funkcje 02h przerwania 21h oraz znak "carriage return" o kodzie ASCII 13d
	    int 21h
		 		
        mov ah, 0h						; oczekujemy na nacisniecie dowolnego klawisza
	    int 16h  
            
        mov	ah, 4ch     				; zakonczenie dzialania programu
		int	21h
		
code1 ends
		
stack1	segment stack					; miejsce na stos (100 slow)
		dw 100 dup (?)
top1	dw ?
stack1 ends

end start1