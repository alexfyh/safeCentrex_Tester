#!/bin/bash

##Fijarse de no imprimir nada por pantalla salvo el resultado ECHO

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