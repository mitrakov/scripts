#!/usr/bin/env python3
import sys
import argparse

WORDS = [
    "be", "am", "are", "is", "was", "I", "you", "the", "a", "an", "to", "it", "not", "and", "of", "do", "did", "had", "has", "we", "in", "get", "got", "my", "me", "go", "oh", "can", "no", "on", "for", "all", "so", "he", "but", "out", "up",
    "say", "now", "at", "one", "hey", "see", "saw", "if", "how", "she", "guy", "let", "her", "uh", "um", "him", "why", "who", "as", "our", "yes", "man", "men", "his", "us", "or", "OK", "way", "too", "by", "day", "two", "God",
    "off", "big", "try", "dad", "kid", "boy", "put", "bad", "any", "Mr", "use", "mom", "may", "hi", "new", "lot", "ask", "hmm", "hm", "met", "huh", "old", "wow", "eat", "ate", "run", "ran", "car", "ah", "aah", "job", "fun",
    "buy", "son", "sit", "sat", "own", "dog", "die", "sir", "sex", "pay", "hot", "win", "won", "eye", "aw", "hit", "yet", "ten", "ass", "gay", "few", "ow", "yow", "lie", "lay", "ago", "end", "its", "ha", "hah", "fat", "cut",
    "bit", "bed", "six", "set", "bar", "bye", "box", "bet", "tho", "Mrs", "cat", "hat", "mm", "cry", "act", "eh", "god", "bag", "shh", "sh", "key", "red", "yep", "mad", "ice", "war", "fly", "top", "far", "leg", "air", "gun",
    "ahh", "fix", "ugh", "hid", "sad", "pie", "ho", "law", "egg", "art", "arm", "bus", "age", "yay", "fan", "owe", "led", "pee", "cup", "cop", "pig", "Jew", "rid", "Ms", "Mss", "pop", "cow", "ear", "toy", "Net", "fit", "gas",
    "ew", "eww", "fed", "ma", "tea", "cab", "pen", "sea", "yo", "add", "low", "nah", "rat", "tie", "sun", "dig", "dug", "tip", "rip", "pal", "gee", "gym", "wet", "beg", "uhh", "sox", "gum", "mix", "hoo", "lip", "oil", "bra",
    "tax", "nut", "sue", "pot", "due", "rub", "sky", "lab", "row", "hug", "van", "tub", "ad", "ads", "bee", "dry", "toe", "hip", "pet", "bum", "bug", "nap", "tag", "per", "ton", "odd"
]
DECODE_MAP = {word: i for i, word in enumerate(WORDS)} # reverse map for O(1) decoding lookups

def encode(file_path):
    with open(file_path, "rb") as f:
        data = f.read()                                # read file as bytes
        encoded = [WORDS[b] for b in data]             # map each byte to its corresponding word
        print(" ".join(encoded))

def decode(file_path):
    with open(file_path, "r") as f:
        words = f.read().split()
        decoded = bytes([DECODE_MAP[word] for word in words])
        sys.stdout.buffer.write(decoded)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Encode/Decode file using word mapping.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-e", action="store_true", help="Encode file")
    group.add_argument("-d", action="store_true", help="Decode file")
    parser.add_argument("file", help="Input file path")

    args = parser.parse_args()

    if args.e:
        encode(args.file)
    else:
        decode(args.file)
