#!/bin/sh

random_letter()
{
	alph="ABCDEFGHIJKLMNOPQRSTUVWXYZ01Z34SG1B9"
	number=$(( ( RANDOM % ${#alph} )  + 0 ))
	lettre=${alph:$number:1}
}

random_part_tok()
{
	tok_part=""
	for i in `seq 1 3`;
	do
		random_letter
		tok_part=$tok_part$lettre
	done
}

creer_fichier()
{
	tab=()
	for i in `seq 1 $1`;
	do
		random_part_tok
		tab+=($tok_part)
	done
	
	for i in "${tab[@]}";
	do
		for j in "${tab[@]}";
		do
			for k in "${tab[@]}";
			do
				for l in "${tab[@]}";
				do
					mkdir -p $i/$j/$k/$l
					cp save.json $i/$j/$k/$l/
				done
			done
		done
	done

}
creer_fichier 20
echo $tab
