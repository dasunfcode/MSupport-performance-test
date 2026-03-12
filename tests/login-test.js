import http from 'k6/http';
import { check, sleep, open } from 'k6';

// This test logs each user directly; it intentionally does **not** import the
// shared `generateTokenPool` helper because it's the one exception to running
// the token-generation step at startup.
const usersData = JSON.parse(open('../data/test_users.json'));

export const options = {
  vus: 100,        // 100 virtual users
  duration: '2m',  // test duration
};

export default function () {

  // Each VU gets a unique user
  const user = usersData[(__VU - 1) % usersData.length];

  const payload = JSON.stringify({
    email: user.email,
    password: user.password
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'x-timezone': 'Asia/Colombo'
    }
  };

  const res = http.post(
    'https://qa.msupport.mone.am/api/v1/auth/login',
    payload,
    params
  );

  check(res, {
    'login successful': (r) => r.status === 200,
  });

  console.log(`VU ${__VU} logged in with ${user.email} - status: ${res.status}`);

  sleep(1);
}