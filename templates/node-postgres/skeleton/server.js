const http = require('http');
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

const server = http.createServer(async (req, res) => {
  if (req.url === '/health') {
    try {
      const result = await pool.query('SELECT NOW()');

      res.writeHead(200, {
        'Content-Type': 'application/json',
      });

      return res.end(
        JSON.stringify({
          status: 'ok',
          database: 'connected',
          time: result.rows[0].now,
        }),
      );
    } catch (error) {
      res.writeHead(500, {
        'Content-Type': 'application/json',
      });

      return res.end(
        JSON.stringify({
          status: 'error',
          database: 'disconnected',
          error: error.message,
        }),
      );
    }
  }

  res.writeHead(200, {
    'Content-Type': 'application/json',
  });

  res.end(
    JSON.stringify({
      application: '${{ values.appName }}',
      message: 'Provisioned by Backstage',
    }),
  );
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Application listening on port 3000');
});
