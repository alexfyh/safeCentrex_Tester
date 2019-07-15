#!/bin/bash

##	IMPORTANTE	CORRERLO COMO SUDO, SINO NO CORRE LOS KILLALL Y PS -PUTAN
##	HACER UNA GUÍA DE LOS PARÁMETROS RECIBIDOS?????

## TODO	=	Cambiar las variables de las funciones a local así no hay forma que se pisen el contenido
## Ver = no se puede cambiar el sleep con adelantar tiempo ya que es necesario eseperar que el proceos se levante bien
## https://www.linuxjournal.com/content/return-values-bash-functions


. /home/voipgroup/git_safeCentrex/safeCentrex_Tester/condiciones_safeCentrex.sh

oneTimeSetUp(){
	##	Verificar si Safe Centrex se encuentra "instalado"
	existe_safeCentrex=$(which safe_centrex)
	if [[ -z $existe_safeCentrex ]]; then
		##echo "No hay una proceso asterisk ejecutàndose"
		echo 	"No hubo proceso Safe Centrex ejecutándose antes de la prueba, no tiene sentido correr las pruebas"
		echo 	"Ver la forma de truncar la prueba acá"
		exit 1
	fi
	segundos_adelantados=0
}

oneTimeTearDown(){
	echo "Segundos adelantado = " $segundos_adelantados
}

adelantarSegundos(){
	sudo date -s "$1 seconds">>/dev/null
	segundos_adelantados=$((segundos_adelantados+$1))
}

setUp(){
	## Reinicio asterisk y centrex matando primero a safe_centrex y luego asterisk
	sudo rm -f /var/www/backups/safe_centrex_*
	sudo killall safe_centrex
	sudo killall asterisk
	sudo safe_centrex
	
	sleep 10
	
	cantidad_safecentrex_corriendo=$(ps -aux | grep safe_centrex | grep "/bin/sh" | wc -l)
	## TODO =  ver qué hacer si la inicialización de la prueba falló
	assertEquals "Inicializacion falló" 1 $cantidad_safecentrex_corriendo 

	asterisk_status=$(check_AsteriskUp)
	safeCentrex_status=$(check_SafeCentrexUp)
	##echo "Estado del Asterisk		=" $asterisk_status
	##echo "Estado del Safe Centrex	=" $safeCentrex_status
	initial_conditions=$(($asterisk_status&&$safeCentrex_status))
	assertEquals "Asterisk o Safe Centrex no se encuentran corriendo" 1 $initial_conditions
}

tearDown(){
	echo "Se adelantaron " $segundos_adelantados "segundos"
	sudo date -s "$segundos_adelantados seconds ago">>/dev/null
	segundos_adelantados=0
	echo "--------------------------------------------------------------------------------------------------------------------------"
}
test_When_AsteriskCae5VecesCada1Minuto_Then_AsteriskSigueEstandoLevantando(){
	##	Precondiciones antes de iniciar la prueba
	
	numero_backups_previos=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	
	## Si la inicialización está bien, no hace falta adelantar 10 minutos
	##sudo date -s "10 minutes"
	cantidad_caidas=5
	for (( i = 0; i < $cantidad_caidas; i++ )); do
		killall -9 asterisk
		sleep 15
		asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
		assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " 1 $asterisk_listening
		
		adelantarSegundos 30
	done
	numero_backups_actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	numero_esperado=$(($numero_backups_previos+$cantidad_caidas))
	assertEquals "Cantida de backups no consistente " $numero_esperado $numero_backups_actuales
}

test_When_AsteriskCae13VecesCada2Minutos_Then_AsteriskNoSeEncuentraCorriendo(){
	numero_backups_previos=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	cantidad_caidas=14
	for (( i = 0; i < $cantidad_caidas; i++ )); do
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
		echo "Numero back ups actuales" $actuales
		killall -9 asterisk>>/dev/null
		sleep 5
		asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
		echo $asterisk_listening
		if [[ $i -lt 10 ]]; then
			echo "Iteracion menor de 10 = " $i 
			
			#assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " 1 $asterisk_listening
		else
			echo "Iteracion mayor que 10 = " $i
			#assertEquals "Asterisk después de 10 caídas no debería estar escuchando " 0 $asterisk_listening
		fi
		adelantarSegundos 30
		echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
	done
	numero_backups_actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	sleep 5
	##	Número de backupps cuando el número de caídas es mayor a 10 siempre es 10 más del previo 
	numero_esperado=$(($numero_backups_previos+10))
	echo "num esperado" $numero_esperado
	assertEquals "Cantida de backups no consistente " $numero_esperado $numero_backups_actuales
}


test_WhenAsteriskCae5VecesCada1MinutoLuego7VecesCada1Minuto_Then_AsteriskSigueEstandoLevantando(){
	##	Luego hacer referencia a después de 10 minutos.
	##	Test válido para comprobar el conteo a 0 después de 10 minutos
	echo "Definir test"
}
test_When_SafeCentrexNoEstaCorriendoYUserNoAutorizadoTrataDeInicializarlo_Then_SafeCentrexNoInicia(){
	echo "Definir test"
}
. /home/voipgroup/shunit2-2.1.7/shunit2
