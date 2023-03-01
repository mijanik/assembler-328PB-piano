;
; Projekt_MJ_AK.asm
;
; Author : Miłosz Janik & Antoni Kijania
;
; Taktowanie zegara: 16MHz
; 328PB Xplained Mini

;----------INICJALIZACJA----------

.CSEG
.ORG 0x00

rjmp init

.ORG PCINT2addr
rjmp pcint2_isr

init:
;inicjalizacja stosu
ldi R16, HIGH(RAMEND)
out SPH, R16
ldi R16, LOW(RAMEND)
out SPL, R16

;inicjalizacja portu C_0 jako wyjscia
sbi ddrc, 0
;inicjalizacja calego portu D jako wejscia
ldi r17, 0x00
out ddrd, r17

ldi r17, 0xFF
out portd, r17 ;pull-up na wejściu - port D

;ustawienie przerwań na całym porcie D (zmiana stanu wejścia)
ldi r17, (1<<pcint16)|(1<<pcint17)|(1<<pcint18)|(1<<pcint19)|(1<<pcint20)|(1<<pcint21)|(1<<pcint22)|(1<<pcint23)
sts pcmsk2, r17

ldi r17, (1<<pcie2)
sts pcicr, r17

sei

;Pamięć danych - deklarujemy zmienną przechowującą później długość czasu stanu wysokiego/niskiego pojedynczego pisku
.DSEG
.ORG 0x100 
okres: .BYTE 1 ;1 bajtowa zmienna w pamieci

;pamięć programu ciąg dalszy
.CSEG 
.ORG 0x110

;----------GŁÓWNY PROGRAM----------

;główny program:
stop:
	sleep ;czekanie na przerwanie
	jmp stop

;----------DETEKCJA PRZYCISKU----------

;po wykryciu przerwania, sprawdzamy stany wszystkich wejść po kolei:
pcint2_isr: 
	sbis pinD, 0
	call przycisk1

	sbis pinD, 1
	call przycisk2

	sbis pinD, 2
	call przycisk3

	sbis pinD, 3
	call przycisk4

	sbis pinD, 4
	call przycisk5

	sbis pinD, 5
	call przycisk6

	sbis pinD, 6
	call przycisk7

	sbis pinD, 7
	call przycisk8

	reti

;----------OBSŁUGA PRZYCISKU----------

;t_H = 5042 takty = 0,315ms 
;t_L = 4020 takty = 0,25ms
;f ~= 3550Hz
przycisk1:
	ldi R20, 210
	sts okres, R20 ;wczytanie zmiennej okresu - od której zależy częstotliwość piszczenia
	call piszczenie
	
	czekaj1: ;czekaj dopóki klikający nie puści przycisku
		sbic pinD, 0
		ret
		rjmp czekaj1


;t_H = 4802 takty = 0,3ms
;t_L = 3830 takty = 0,24ms
;f = 3700Hz
przycisk2:
	ldi R20, 200
	sts okres, R20
	call piszczenie
	
	czekaj2:
		sbic pinD, 1
		ret
		rjmp czekaj2


;t_H = 4562 takty = 0,29ms
;t_L = 3640 takty = 0,23ms
;f = 3850Hz
przycisk3:
	ldi R20, 190
	sts okres, R20
	call piszczenie
	
	czekaj3:
		sbic pinD, 2
		ret
		rjmp czekaj3


;t_H = 4322 takty = 0,27ms
;t_L = 3450 takty = 0,22ms
;f = 4050Hz
przycisk4:
	ldi R20, 180
	sts okres, R20
	call piszczenie
	
	czekaj4:
		sbic pinD, 3
		ret
		rjmp czekaj4


;t_H = 4082 takty = 0,26ms
;t_L = 3260 takty = 0,2ms
;f = 4350Hz
przycisk5:
	ldi R20, 170
	sts okres, R20
	call piszczenie
	
	czekaj5:
		sbic pinD, 4
		ret
		rjmp czekaj5


;t_H = 3842 takty = 0,24ms
;t_L = 3070 takty = 0,19ms
;f = 4650Hz
przycisk6:
	ldi R20, 160
	sts okres, R20
	call piszczenie
	
	czekaj6:
		sbic pinD, 5
		ret
		rjmp czekaj6


;t_H = 3602 takty = 0,23ms
;t_L = 2880 takty = 0,18ms
;f = 4850Hz
przycisk7:
	ldi R20, 150
	sts okres, R20
	call piszczenie
	
	czekaj7:
		sbic pinD, 6
		ret
		rjmp czekaj7


;t_H = 3362 takty = 0,21ms
;t_L = 2690 takty = 0,17ms
;f = 5250Hz
przycisk8:
	ldi R20, 140
	sts okres, R20
	call piszczenie
	
	czekaj8:
		sbic pinD, 7
		ret
		rjmp czekaj8

;----------PISK----------

; 1 takt = 6,25 * 10^(-8) sekundy

; długość stanu wysokiego: (okres * 5 * 4t) + 2t + okres * 1t + okres * 1t + okres * 2t + 2t
; = okres * 20t + okres * (1t + 1t + 2t) + 2t = okres * 24t + 2t

; długość stanu niskiego: 8t + 1t + 1t + (okres * 4 * 4t) + okres * 1t + okres * 2t + 6t + 4t + [7:11 taktów w piszczenie]
; =~ 10t + okres * 16t + okres * 3t + 20t = okres * 19t + 30t

;pojedynczy pisk - stan wysoki i następnie stan niski o określonej długości
pisk: 
  push R16				  ;2 takty
  push R17				  ;2 takty
  push R18				  ;2 takty

  sbi portc, 0x00		  ;2 takty

 ;petle opozniajace:
  lds R16, okres          ;2 takty
  opoznienie1:
    ldi R17, 5            ;1 takt
    opoznienie2:  
        nop               ;1 takt
        dec R17           ;1 takt
        brne opoznienie2  ;2 takty //1 takt jeżeli wychodzi z pętli (1 raz)
  dec R16                 ;1 takt
  brne opoznienie1        ;2 takty //1 takt jeżeli wychodzi z pętli (1 raz)

  cbi portc, 0x00         ;2 takty

 ;petle opozniajace:
  mov R16, R21            ;1 takt
  opoznienie11:
    ldi R17, 4			  ;1 takt 
    opoznienie22: 
        nop				  ;1 takt
        dec R17			  ;1 takt
        brne opoznienie22 ;2 takty //1 takt jeżeli wychodzi z pętli (1 raz)
  dec R16                 ;1 takt
  brne opoznienie11       ;2 takty //1 takt jeżeli wychodzi z pętli (1 raz)

  pop R18				  ;2 takty
  pop R17				  ;2 takty
  pop R16				  ;2 takty

  ret                     ;4 takty

;----------PISZCZENIE----------

piszczenie: ;ona wywołuje pojedyncze piski określoną ilość razy
  push R16
  push R17
  push R18
  push R19
  push R20
  push R21
  push R22
  
  ;kompensacja długości pisku - gdy okres jest dłuższy to trzeba zmneijszyć ilość pojedynczych pisków (aby dźwięki miały tą samą długość):
  ldi R19, 255
  lds R20, okres
  sub R19, R20

  ;tryb specjalny - ustaw więcej niż 0 aby spowodować zwiększanie t_L w czasie pisku:
  lds R21, okres
  ldi R22, 0

  ;wywoływanie pisku:
  mov R16, R19
  opoznienie111:
	ldi R17, 20
	add R21, R22
	opoznienie222:
		call pisk
		dec R17
		brne opoznienie222
  dec R16
  brne opoznienie111

  pop R22
  pop R21
  pop R20
  pop R19
  pop R18
  pop R17
  pop R16

  ret