#!/bin/bash

##	IMPORTANTE	CORRERLO COMO SUDO, SINO NO CORRE LOS KILLALL Y PS -PUTAN
##	HACER UNA GUÍA DE LOS PARÁMETROS RECIBIDOS?????

## TODO	=	Cambiar las variables de las funciones a local así no hay forma que se pisen el contenido

## https://www.linuxjournal.com/content/return-values-bash-functions


. /home/voipgroup/git_safeCentrex/safeCentrex_Tester/condiciones_safeCentrex.sh
test_When_AsteriskCae5VecesMuySeguidas_Then_AsteriskSigueEstandoLevantando(){
	##	Precondiciones antes de iniciar la prueba
	asterisk_status=$(check_AsteriskUp)
	safeCentrex_status=$(check_SafeCentrexUp)
	echo "Estado del Asterisk		=" $asterisk_status
	echo "Estado del Safe Centrex	=" $safeCentrex_status
	initial_conditions=$(($asterisk_status&&$safeCentrex_status))
	assertEquals "Asterisk o Safe Centrex no se encuentran corriendo" $initial_conditions 1

	numero_backups_previos=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	
	sudo date -s "10 minutes"
	cantidad_caidas=5
	for (( i = 0; i < cantidad_caidas; i++ )); do
		killall -9 asterisk
		sleep 20
		asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
		assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " $asterisk_listening 1
	done
	##sudo date -s "10 minutes"	
}
test1(){
	echo "hola"
}

test2(){
	echo "hola2"
}
. /home/voipgroup/shunit2-2.1.7/shunit2
