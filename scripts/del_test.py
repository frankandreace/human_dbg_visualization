test_array = [5,1,2,3,2,4,5,6,3,2,7,8]

start = 0
mv_start = start

to_del = []

while(mv_start < (len(test_array) - 1)):
    mv_start+=1
    print(f"At pos {mv_start}: value {test_array[mv_start]}")
    if (test_array[mv_start] < test_array[start]):
        to_del.append(mv_start)

for el in reversed(to_del):
    del test_array[el]

print(test_array)

del test_array[1:1]

print(test_array)