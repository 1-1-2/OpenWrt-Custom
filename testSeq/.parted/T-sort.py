# -*- coding: utf-8 -*-
"""
Created at Tue Jul 12 20:21:05 2022
Modified at Mon Aug 07 23:31:44 2023
@author: USN
"""


def merge_acc_keys(ori_dict, sorted_keys):
    # merge into lines
    sorted_lines = list()
    for each_key in sorted_keys:
        sorted_lines.append(each_key + '\n')
        sorted_lines.extend([i + '\n' for i in ori_dict[each_key]])

    return sorted_lines


def sort_keys(ori_keys):
    # baseline first
    if '@ Baseline' in ori_keys:
        ori_keys.remove('@ Baseline')
        sorted_keys = ['@ Baseline'] + sorted(ori_keys)
    else:
        sorted_keys = sorted(ori_keys)

    return sorted_keys


def sort_seq_file(ori_file):
    # seq to dict
    ori_dict = dict()
    with open(ori_file, 'r') as f:
        texts = f.read()
    for each_set in texts.split('@')[1:]:
        lines = each_set.splitlines()
        title, configs = f"@{lines[0]}", lines[1:]
        if ori_dict.get(title):
            print('[发现重复标题]', title)
        configs.sort()
        ori_dict[title] = configs

    # sort keys
    ori_keys = list(ori_dict.keys())
    sorted_keys = sort_keys(ori_keys)

    return {'file': ori_file,
            'ori_dict': ori_dict,
            'sorted_keys': sorted_keys}


if __name__ == '__main__':
    # 排序，结果写入*_sorted.ini
    # 同时以排序前文件名为key，内容为value存到AIO
    all_dict = dict()
    parted_list = ["both.ini", "lean's lede.unique.ini", "openwrt.unique.ini"]
    seq_list = ["lean's lede.ini", "openwrt.ini"]

    print(f"[1]parted_list:{parted_list}\n[2]seq_list:{seq_list}")
    while True:
        try:
            selection = input('执行哪个序列:')
            if selection == '1':
                tg_list = parted_list
            elif selection == '2':
                tg_list = seq_list
            else:
                continue
            break
        except:
            print('请只输入一个数字.')

    for each in tg_list:
        with open(each[:-4] + '_sorted.ini', 'w') as f:
            tmp = sort_seq_file(each)
            all_dict[each] = tmp
            lines = merge_acc_keys(tmp['ori_dict'], tmp['sorted_keys'])
            f.writelines(lines)

    # make_diff()


def make_diff():
    lede_dict = all_dict["lean's lede.ini"]
    openwrt_dict = all_dict["openwrt.ini"]

    lede_keys = set(lede_dict['sorted_keys'])
    openwrt_keys = set(openwrt_dict['sorted_keys'])

    both_keys = lede_keys & openwrt_keys
    lede_unique_keys = lede_keys - openwrt_keys
    openwrt_unique_keys = openwrt_keys - lede_keys

    with open('both.lede.txt', 'w') as f:
        lines = merge_acc_keys(lede_dict['ori_dict'], sorted(both_keys))
        f.writelines(lines)

    with open('both.openwrt.txt', 'w') as f:
        lines = merge_acc_keys(openwrt_dict['ori_dict'], sorted(both_keys))
        f.writelines(lines)

    with open('openwrt.unique.txt', 'w') as f:
        lines = merge_acc_keys(
            openwrt_dict['ori_dict'], sorted(openwrt_unique_keys))
        f.writelines(lines)

    with open('lede.unique.txt', 'w') as f:
        lines = merge_acc_keys(lede_dict['ori_dict'], sorted(lede_unique_keys))
        f.writelines(lines)
