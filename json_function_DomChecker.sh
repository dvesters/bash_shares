#!/bin/bash
mfs=';'
msfs=':'
HEADER='"Domainname";"Site location";"Site resolved subdomain";"Site IP";"Site ASN";"Mail location";"Mail IP";"Mail ASN";"NS Location";"NS IP";"NS ASN";"DDS";"ViBo";"ALL ViBo values";"Found IS Hosting";"IS hosting type";"IS ParentDomain";"IS Hostname";"IS Founds";"Concl. Registraion";"Concl. Location"'
PRINT='"d-bass.nl";"internal";"www.";"85.158.253.209";"21155";"internal";"141.138.198.56";"35470";"internal";"80.84.224.44";"21155";"unknown";"active";"deleted:active";"";"hosting";"";"srv12057.hostingserver.nl";"1";"ACTIVE";"INTERNAL"'



function Json {
		orig_IFS=${IFS}
		declare IFS=${mfs}

		aHEADER=(${HEADER//\"/})
		aPRINT=(${PRINT//\"/})

		IFS=${orig_IFS}

		declare -i LOOP_COUNT=${#aHEADER[@]}

		echo -n "{ \"${DOMAIN}\" : { \"information\" : { " 
		for int in $(seq 0 1 $((${LOOP_COUNT} -1)))
		do
			declare -i SUB_COUNT=$(tr -cd "${msfs}" <<< ${aPRINT[$int]} |wc -c)
			if [[ ${SUB_COUNT} -gt 0 ]]
			then
				orig_IFS=${IFS}
				IFS=${msfs}
				aSUB_SET=(${aPRINT[$int]})
				IFS=${orig_IFS}

				echo -n "\"${aHEADER[$int]}\" : { "
				for s_int in $(seq 0 1 ${SUB_COUNT})
				do
					echo -n "\"${aHEADER[$int]} ${s_int}\" : " 
					if [[ $( grep -oE "^[0-9]*$" <<< ${aSUB_SET[$s_int]}) ]] || [[ ${aSUB_SET[$s_int]:-empty} =~ (true|false|null|NULL) ]]
					then
						echo -n ${aSUB_SET[$s_int]}
					else
						echo -n "\"${aSUB_SET[$s_int]}\""
					fi
					if [[ ${s_int} -lt ${SUB_COUNT} ]]
					then
						 echo -n ', '
					fi
				done && echo -n ' },'

			else
				echo -n "\"${aHEADER[$int]}\" : " 
				if [[ $( grep -oE "^[0-9]*$" <<< ${aPRINT[$int]}) ]] || [[ ${aPRINT[$int]:-empty} =~ (true|false|null|NULL) ]]
				then
					echo -n ${aPRINT[$int]}
				else
					echo -n "\"${aPRINT[$int]}\""
				fi
				if [[ ${int} -lt $((${LOOP_COUNT} -1)) ]]
				then
					echo -n ', '
				fi
			fi
		done
		echo ' }}}'
}

Json '.' jq




#### Just for fun nog een klein stukje code wat ik wel kan delen. Vind de bedachte array loop wel leuk bedacht.
#
# INPUT is
# domeinnaam;account_type;parent_domein;hostname 
# En wanneer een domein meer dan 1 keer op het platform voorkomt wordt deze set van 4 aangevuld met nog een set 
# domeinnaamA;account_typeA;parent_domeinA;hostnameA;domeinnaamB;account_typeB;parent_domeinB;hostnameB
# 
### account_type = ('hosting'|'alias'|'emailonly'|'forward'|'subdomain')

function SharedHostingCheck {

	unset FOUND HOSTING_INFO TYPE SERVER P_DOMAIN

	orig_IFS=${IFS}
	####################################################
	# IFS is not ${mfs} but the FS in the curl page
	# Do not eddit!
	declare IFS=';'
	declare HOSTING_INFO=($(curl -so /dev/stdout "${HOSTING_DOMAIN_URL}${DOMAIN}" |sed 's/\;$//' |tr -cd '[[:alnum:]]\-\.\;' ))
	####################################################
	IFS=${orig_IFS}

	if [[ ${HOSTING_INFO[0]:-empty} == ${DOMAIN} ]] && [[ ${HOSTING_INFO[1]:-empty} =~ ('hosting'|'alias'|'emailonly'|'forward'|'subdomain') ]] && [[ $(grep -o "${HOSTING_INFO[3]:-empty}" <<< ${HOSTINGSERVERS}) ]]
	then
		declare FOUND=true
		declare -i SH_COUNT=$(echo ${HOSTING_INFO[@]} |grep -o "${DOMAIN}" |wc -l)

		for i in $(seq 0 4 $((${#HOSTING_INFO[@]}-1)))
		do
			declare TYPE="${TYPE}${TYPE:+${msfs}}${HOSTING_INFO[$((${i}+1))]}"
			declare P_DOMAIN="${P_DOMAIN}${SERVER:+${msfs}}${HOSTING_INFO[$((${i}+2))]}"
			declare SERVER="${SERVER}${SERVER:+${msfs}}${HOSTING_INFO[$((${i}+3))]}"
		done
	else
		declare FOUND=false
	fi

	AddToHeader "Found IS Hosting${mfs}IS hosting type${mfs}IS ParentDomain${mfs}IS Hostname${mfs}IS Founds"
	AddToPrint "${FOUNT}${mfs}${TYPE}${mfs}${P_DOMAIN}${mfs}${SERVER}${mfs}${SH_COUNT:-0}"

	unset FOUND HOSTING_INFO TYPE SERVER P_DOMAIN
		
}
