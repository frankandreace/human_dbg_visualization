from sys import argv
from sys import stderr

def update_modify_range(mapped_ranges,lp,boundaries):
    mapped_ranges[lp][1] = max(mapped_ranges[lp][1],boundaries[1])
    original_lp = lp

    while (lp < len(mapped_ranges) - 1):
        lp+=1
        if ((mapped_ranges[original_lp][0] <= mapped_ranges[lp][0]) and (mapped_ranges[original_lp][1] >= mapped_ranges[lp][0])):
            mapped_ranges[original_lp][1] = mapped_ranges[lp][1]
        else: break
    del mapped_ranges[original_lp+1:lp]

def scan_paf_get_boundaries(paf_file: str):

    query_sequence_name = ""
    start_boundary = 0
    end_boundary = 0
    mapped_ranges = []
    inserted = False

    with open(paf_file) as f:

        for line in f:
            inserted = False
            lp=0
            fields = line.strip().split('\t')
            if end_boundary == 0 : end_boundary = int(fields[1])
            if len(query_sequence_name) == 0: query_sequence_name = fields[0]
            boundaries = [int(fields[2]),int(fields[3])]

            while (lp < len(mapped_ranges)):

                if (mapped_ranges[lp][0] < boundaries[0]):
                    if (mapped_ranges[lp][1] >= boundaries[0]):
                        update_modify_range(mapped_ranges,lp,boundaries)
                        lp+=1
                        inserted = True
                        break

                elif (mapped_ranges[lp][0] == boundaries[0]):
                    update_modify_range(mapped_ranges,lp,boundaries)
                    lp+=1
                    inserted = True
                    break

                else:
                    if (mapped_ranges[lp][0] <= boundaries[1]):
                        update_modify_range(mapped_ranges,lp,boundaries)
                        lp+=1
                        inserted = True
                        break
                    else:
                        break
                lp+=1

            if (inserted == False): mapped_ranges.insert(lp,boundaries)
    
    check_function(mapped_ranges)

    #NOW I PRINT A NEGATION OF SUCH BOUNDARIES
    
    for ranges in mapped_ranges:
        if (ranges[0]-start_boundary) > 0:
            print(f"{query_sequence_name}\t{start_boundary}\t{ranges[0]}")
        start_boundary = ranges[1]
    if (end_boundary - start_boundary) > 0:
        print(f"{query_sequence_name}\t{start_boundary}\t{end_boundary}")



def check_function(ranges_list):
    for i in range(len(ranges_list)-1):
        if ranges_list[i][0] > ranges_list[i][1]:
            print(f'ERORR at POS {i}: START > END.',file=stderr)
            break
        if ranges_list[i][1] >= ranges_list[i+1][0]:
            print(f"ERROR at {i}-{i+1}. END of {i} >= START OF {i+1}",file=stderr)
            print(f"POS: {i}\tSTART: {ranges_list[i][0]}\tEND: {ranges_list[i][1]}",file=stderr)
            print(f"POS: {i+1}\tSTART: {ranges_list[i+1][0]}\tEND: {ranges_list[i+1][1]}",file=stderr)
            break


if __name__ == "__main__":
    scan_paf_get_boundaries(argv[1])
