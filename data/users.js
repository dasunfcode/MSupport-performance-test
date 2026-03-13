// data/users.js

function getUniqueRandomNumbers(count, min, max) {
    const numbers = new Set();
    while (numbers.size < count) {
        const num = Math.floor(Math.random() * (max - min + 1)) + min;
        numbers.add(num);
    }
    return Array.from(numbers);
}

const randomNumbers = getUniqueRandomNumbers(5, 1, 100);

export const users = randomNumbers.map((num) => ({
    email: `testuser${num}@example.com`,
    password: "Test@1234"
}));