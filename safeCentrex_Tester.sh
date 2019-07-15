#!/bin/bash

##	TODO = Refactorizar para que sea ejecutado de forma remota,así SUT no necesita agregar nada como shUnit

##	TODO = Definir si está bien que se banque 12 caídas en vez de 10 y descomentar el test que falla

##	IMPORTANTE	CORRERLO COMO SUDO, SINO NO CORRE LOS KILLALL Y PS -PUTAN
##	HACER UNA GUÍA DE LOS PARÁMETROS RECIBIDOS?????

## TODO	=	Cambiar las variables de las funciones a local así no hay forma que se pisen el contenido
## Ver = no se puede cambiar el sleep con adelantar tiempo ya que es necesario eseperar que el proceos se levante bien
## https://www.linuxjournal.com/content/return-values-bash-functions

suite(){
	##En esta función se agregan los test que se van a correr
	## Sin esta funciòn, se corren todas las funciones que comienzan con la palabra test
	suite_addTest test_When_AsteriskCae5VecesSeguidas_Then_AsteriskSigueEstandoLevantando
	suite_addTest test_When_AsteriskCae14VecesSeguidas_Then_AsteriskNoSeEncuentraCorriendo
	suite_addTest test_WhenAsteriskCae5VecesSeguidasLuego8VecesSeguidas_Then_AsteriskSigueEstandoLevantando
	suite_addTest test_When_elDiscoEstaLleno_SiAsteriskCae_Then_NohayProcesoAsteriskCorriendo
	suite_addTest test_When_SafeCentrexEsIniciadoComoUsuarioNoRoot_Then_SafeCentrexNoSeEncuentraCorriendo
	suite_addTest test_When_SafeCentrexEsIniciadoComoRoot_Then_SafeCentrexSeEncuentraCorriendo
}

oneTimeSetUp(){
	##	Corre solamente una vez antes de correr las pruebas 
	##	Verificar si Safe Centrex se encuentra "instalado"
	existe_safeCentrex=$(which safe_centrex)
	if [[ -z $existe_safeCentrex ]]; then
		##echo "No hay una proceso asterisk ejecutàndose"
		echo 	"No hubo proceso Safe Centrex ejecutándose antes de la prueba, no tiene sentido correr las pruebas"
		echo 	"Ver la forma de truncar la prueba acá"
		exit 1
	fi
	segundos_adelantados=0
	tiempo_espera=10
}

oneTimeTearDown(){
	##	Corre sólo una vez al finalizar de correr todas las pruebas
	echo "Segundos adelantado = " $segundos_adelantados
}

adelantarSegundos(){
	sudo date -s "$1 seconds">>/dev/null
	segundos_adelantados=$((segundos_adelantados+$1))
}

setUp(){
	##	Corre antes de iniciar cada prueba
	## Reinicio asterisk y centrex matando primero a safe_centrex y luego asterisk
	sudo rm -f /var/www/backups/safe_centrex_*
	sudo killall safe_centrex
	sudo killall asterisk
	sudo safe_centrex
	sleep $tiempo_espera
	cantidad_safecentrex_corriendo=$(ps -aux | grep safe_centrex | grep "/bin/sh" | wc -l)
	## TODO =  ver qué hacer si la inicialización de la prueba falló
	assertEquals "Inicializacion falló" 1 $cantidad_safecentrex_corriendo 

	asterisk_status=$(check_AsteriskUp)
	safeCentrex_status=$(check_SafeCentrexUp)
	initial_conditions=$(($asterisk_status&&$safeCentrex_status))
	assertEquals "Asterisk o Safe Centrex no se encuentran corriendo" 1 $initial_conditions
	echo "-------------------------		INICIO DE PRUEBA	--------------------"
}

tearDown(){
	##	Corre después de correr cada prueba
	sudo date -s "$segundos_adelantados seconds ago">>/dev/null
	segundos_adelantados=0
	echo "-------------------------		FIN DE PRUEBA	--------------------"
}


test_When_AsteriskCae5VecesSeguidas_Then_AsteriskSigueEstandoLevantando(){	
	numero_backups_previos=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	cantidad_caidas=5
	for (( i = 0; i < $cantidad_caidas; i++ )); do
		killall -9 asterisk
		sleep $tiempo_espera
		asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
		assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " 1 $asterisk_listening
		adelantarSegundos 30
	done
	numero_backups_actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	numero_esperado=$(($numero_backups_previos+$cantidad_caidas))
	assertEquals "Cantida de backups no consistente " $numero_esperado $numero_backups_actuales
}

test_When_AsteriskCae14VecesSeguidas_Then_AsteriskNoSeEncuentraCorriendo(){
	numero_backups_previos=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	cantidad_caidas=14
	for (( i = 0; i < $cantidad_caidas; i++ )); do
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
		echo "Numero back ups actuales antes de la caida" $actuales
		killall -9 asterisk>>/dev/null
		sleep $tiempo_espera
		asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
		echo "Estado del asterisk antes de la caida = "  $asterisk_listening
		if [[ $i -lt 10 ]]; then
			echo "Iteracion = " $i 
			#assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " 1 $asterisk_listening
		else
			echo "Iteracion = " $i
			#assertEquals "Asterisk después de 10 caídas no debería estar escuchando " 0 $asterisk_listening
		fi
		adelantarSegundos 30
		actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
		echo "Numero back ups actuales después de la caida" $actuales
		echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
	done
	numero_backups_actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	sleep $tiempo_espera
	##	Número de backupps cuando el número de caídas es mayor a 10 siempre es 10 más del previo 
	numero_esperado=$(($numero_backups_previos+10))
	echo "num esperado" $numero_esperado
	assertEquals "Cantida de backups no consistente " $numero_esperado $numero_backups_actuales
}

test_WhenAsteriskCae5VecesSeguidasLuego8VecesSeguidas_Then_AsteriskSigueEstandoLevantando(){
	##	Luego hacer referencia a después de 10 minutos.
	##	Test válido para comprobar el conteo a 0 después de 10 minutos
	numero_backups_previos=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	cantidad_caidas=5
	for (( i = 0; i < $cantidad_caidas; i++ )); do
		killall -9 asterisk
		sleep $tiempo_espera
		asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
		assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " 1 $asterisk_listening
		
		adelantarSegundos 30
	done
	numero_backups_actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	numero_esperado=$(($numero_backups_previos+$cantidad_caidas))
	assertEquals "Cantida de backups no consistente " $numero_esperado $numero_backups_actuales	

	adelantarSegundos 630

	numero_backups_previos=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	cantidad_caidas=5
	for (( i = 0; i < $cantidad_caidas; i++ )); do
		killall -9 asterisk
		sleep $tiempo_espera
		asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
		assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " 1 $asterisk_listening
		adelantarSegundos 30
	done
	numero_backups_actuales=$(ls -l /var/www/backups |  grep safe_centrex | wc -l)
	numero_esperado=$(($numero_backups_previos+$cantidad_caidas))
	assertEquals "Cantida de backups no consistente " $numero_esperado $numero_backups_actuales	
}

test_When_elDiscoEstaLleno_SiAsteriskCae_Then_NohayProcesoAsteriskCorriendo(){
	kiloBytes_disponibles=$(df / --output=avail | tail -n 1 | awk '{$2="K";print $1 $2}')
	fallocate -l $kiloBytes_disponibles	archivo_grande
	df -h
	killall -9 asterisk
	sleep $tiempo_espera
	asterisk_listening=$(check_AsteriskListeningOnPort5060Udp)
	assertEquals "Asterisk no se encuentra escuchando en el puerto 5060 " 0 $asterisk_listening

	rm archivo_grande
	pidof_asterisk=$(pidof asterisk)
	## Tuve que hacer esta negrada porque el bash el envía una cadena vacía y shubit interpreta como que faltan argumentos
	if [ -z "$pidof_asterisk" ]
	then
		resultado_pidof="Inexistente"
	else
		resultado_pidof="Existe 1"
	fi
	##assertTrue "Hay un proceso asterisk corriendo cuando no debería" [ -z "$pidof_asterisk" ] 
	assertEquals "No debería haber algùn proceso Asterisk corriendo" "Inexistente" $resultado_pidof 
}

test_When_SafeCentrexEsIniciadoComoUsuarioNoRoot_Then_SafeCentrexNoSeEncuentraCorriendo(){
	## Test válido para confirmar que sólo el user Root (user id = 0) puede iniciar el safe_centrex	
	## Mato todo los proceos safe_centrex y asterisk activos
	## Supuse que había un sólo proceos safe_centrex corriendo (Verificar en otro test)
	safeCentrex_PID=$(ps -aux | grep "safe_centrex" | grep "/bin/sh" | awk '{print $2}')
	kill $safeCentrex_PID
	killall asterisk
	## Puedo suponer que hay un usuario voipgroup en la mv que no tiene permisos de root ?
	## Ésta fue la única suposición que pude tomar para usar un user diferente al root
	usuarioNoRoot=$( cat /etc/passwd | grep "/bin/bash" | grep -v "root" | awk -F ':' '{print $1}')
	sudo -u $usuarioNoRoot safe_centrex
	safeCentrex_status=$(check_SafeCentrexUp)
	assertEquals "Safe Centrex fue iniciado sin permisos de root" 0 $safeCentrex_status 
}

test_When_SafeCentrexEsIniciadoComoRoot_Then_SafeCentrexSeEncuentraCorriendo(){
	safeCentrex_PID=$(ps -aux | grep "safe_centrex" | grep "/bin/sh" | awk '{print $2}')
	kill $safeCentrex_PID
	killall asterisk
	sudo -u root safe_centrex
	safeCentrex_status=$(check_SafeCentrexUp)
	assertEquals "Safe Centrex no pudo iniciarse siendo ejecutado como root" 1 $safeCentrex_status 
}

test_DefinirTestParaQueNoComienceOtroProceso(){
	echo "TODO = Definir Test"
	##Analizar por PÎD
}

check_AsteriskUp(){
	pidof_asterisk=$(pidof asterisk)
	if [[ -z $pidof_asterisk ]]; then
		##echo "No hay una proceso asterisk ejecutàndose"
		echo 0
	fi
	echo 1
}

check_SafeCentrexUp(){
	##ps -aux | grep 'safe_centrex' | grep 'root'
	## Verificar con un grep /bi/sh
	## Estar seguro que es el proceos ese
	wc_ps_aux=$(ps -aux | grep 'safe_centrex' | wc -l)
	if [[ $wc_ps_aux -ne 2 ]]; then
		##echo "ERROR = Safe centrex no se encuentra corriendo"
		echo 0
	else
		echo 1
	fi
}

check_AsteriskAndSafeCentrexUp(){
	result1=check_AsteriskUp
	result2=check_SafeCentrexUp
	echo $(($result1&&$result2))
}
check_AsteriskListeningOnPort5060Udp(){
	##	Verifica si al menos hay uno
	##	TODO = VER SI ES NECESARIO QUE COMPRUEBE QUE HAY SÓLO UN ASTERISK ESCUCHANDO EN ESE PUERTO
	cantidad_ast_en_5060=$(sudo netstat -putan | grep 'udp' | grep 'asterisk' | awk '{print $4}' | awk -F ":" '{print $2}' | grep '5060' | wc -l)
	if [[ cantidad_ast_en_5060 -gt 0 ]]; then
		echo 1
	else
		echo 0	
	fi	
}
. /home/voipgroup/shunit2-2.1.7/shunit2
