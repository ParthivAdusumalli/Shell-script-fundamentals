#!/bin/bash
word_list=()
while read Line; do
      for word in ${Line[@]};do
              word_list+=("$word")
      done
done < file.txt
echo "Before Duplicates Removing:${word_list[@]}"
word_Set=()
while read Line; do
      for word in ${Line[@]};do
          if [ ${#word_Set[@]} -eq 0 ]; then
              word_Set+=("$word")
          else
              for (( i=0; i < ${#word_Set[@]}; i++)); do
                  if [ "$word" == "${word_Set[$i]}" ]; then
                     break
             elif [ $i -eq $(( ${#word_Set[@]} - 1 )) ]; then
                       word_Set+=("$word")
                       fi
                done
          fi
      done
done < file.txt
echo "After Removing Duplicates:${word_Set[@]}"
for (( i=0; i < ${#word_Set[@]}; i++ )); do
    CurrentWord="${word_Set[$i]}"
    count=1
    for (( j=0; j< ${#word_list[@]}; j++ )); do
        ComparableWord="${word_list[$j]}"
         if [ "$CurrentWord" == "$ComparableWord" ]; then
             count=$count+1
         fi
         done
         echo "Repetation of $CurrentWord - $count"
done