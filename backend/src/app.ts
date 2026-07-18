import express from 'express';
import cors from 'cors';
import notificationsRouter from './routes/notifications';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

app.use('/api/notifications', notificationsRouter);

export default app;
