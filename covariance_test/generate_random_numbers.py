import random
import os

def generate_random_numbers(size):
    result = []

    for i in xrange(size):
        base_value = random.uniform(1, 100)

        result.append(base_value)

    return result


def write_numbers_to_file(numbers, filename):
    with open(filename, 'w+') as file_handle:
        file_handle.writelines([str(f)+'\n' for f in numbers])

    return 0


if __name__ == '__main__':
    numbers = generate_random_numbers(10000)

    dir_path = os.path.dirname(os.path.realpath(__file__))
    file_path = os.path.join(dir_path, 'samples.txt')

    print('Writing to: {}'.format(file_path))

    write_numbers_to_file(numbers, file_path)
