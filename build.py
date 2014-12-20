#!/usr/bin/python2.7

import os, sys, urllib, tarfile, subprocess

environment = [
    'src',
    'src/pcc',
    'src/nim',
    'build',
    'build/pcc',
    'build/nim',
    'eval'
]

print('creating environment...')

for folder in environment:
    next = './' + folder

    if not os.path.exists(next):
        os.makedirs(next)

print('environment created.')
print('generating eval/eval.nim.cfg...')

handle = open('eval/eval.nim.cfg', 'w')
handle.write('arm64.linux.ucc.exe = "./build/pcc/pcc"')
handle.write('ucc.options.linker = "-ldl"')
handle.close()

print('eval/eval.nim.cfg generated.')
print('setting up Portable C Compiler...')
print(' downloading Portable C Compiler (pcc.tgz) to src/pcc/pcc.tgz...')

urllib.urlretrieve('ftp://pcc.ludd.ltu.se/pub/pcc/pcc-current.tgz', 'src/pcc/pcc.tgz')

print(' Portable C Compiler downloaded to src/pcc/pcc.tgz.')
print(' Unpacking src/pcc/pcc.tgz...')

tar = tarfile.open('src/pcc/pcc.tgz', 'r')

for item in tar:
    tar.extract(item, 'src/pcc/')

print(' src/pcc/pcc.tgz unpacked.')
print(' building build/pcc/pcc...')

os.chdir('build/pcc')

subprocess.call(['../../src/pcc/pcc-20141219/configure', '--prefix=' + os.getcwd() + 'build/pcc'])
subprocess.call(['make'])
subprocess.call(['make', 'install'])

print(' build/pcc/pcc built.')
