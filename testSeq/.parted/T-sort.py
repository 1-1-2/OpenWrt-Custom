# -*- coding: utf-8 -*-
"""
Created on Tue Jul 12 20:21:05 2022

@author: USN
"""

import glob


def make_seq_sorted(ori_file, full_return=False):
    with open(ori_file, 'r') as f:
        lines = f.readlines()

    # seq to dict
    ori_dict = dict()
    tmp_key = None
    for line in lines:
        if line.startswith('@'):
            if ori_dict.get(line):
                print('[check duplication]', line)
            tmp_key = line
            ori_dict[tmp_key] = list()
        else:
            ori_dict[tmp_key].append(line)

    # sort keys
    ori_keys = list(ori_dict.keys())

    # sort lines acc2 keys
    sorted_lines = list()
    sorted_keys = sorted(ori_keys)
    for each_key in sorted_keys:
        sorted_lines.append(each_key)
        sorted_lines.extend(sorted(ori_dict[each_key]))

    if full_return:
        return {'lines': lines,
                'ori_dict': ori_dict,
                'sorted_lines': sorted_lines,
                'sorted_keys': sorted_keys}
    else:
        return sorted_lines


seqList = list(set(glob.glob('*.ini')) - set(glob.glob('*_sorted.ini')))
sorted_seq_dict = dict()
for each in seqList:
    with open(each[:-4] + '_sorted.ini', 'w') as f:
        tmp = make_seq_sorted(each, full_return=True)
        sorted_seq_dict[each] = tmp
        f.writelines(tmp['sorted_lines'])

# 懒得抽象了。。先这样吧
def make_diff():
    a = [set(each['sorted_keys']) for each in sorted_seq_dict.values()]
    b = a[0]
    c = a[1]
    tmp = list()
    with open('both.lede.txt', 'w') as f:
        for each_key in sorted(list(b & c)):
            tmp.append(each_key)
            tmp.extend(sorted_seq_dict[seqList[0]]['ori_dict'][each_key])
        f.writelines(tmp)

    tmp = list()
    with open('both.openwrt.txt', 'w') as f:
        for each_key in sorted(list(b & c)):
            tmp.append(each_key)
            tmp.extend(sorted_seq_dict[seqList[1]]['ori_dict'][each_key])
        f.writelines(tmp)

    tmp = list()
    with open('openwrt.unique.txt', 'w') as f:
        for each_key in sorted(list(c - b)):
            tmp.append(each_key)
            tmp.extend(sorted_seq_dict[seqList[1]]['ori_dict'][each_key])
        f.writelines(tmp)

    tmp = list()
    with open('lede.unique.txt', 'w') as f:
        for each_key in sorted(list(b - c)):
            tmp.append(each_key)
            tmp.extend(sorted_seq_dict[seqList[0]]['ori_dict'][each_key])
        f.writelines(tmp)
