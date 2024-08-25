const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
admin.initializeApp();

// Função para enviar notificações diárias
exports.sendDailyNotifications = functions.pubsub.schedule('every day 08:00').timeZone('America/Sao_Paulo').onRun(async (context) => {
  const usersSnapshot = await admin.firestore().collection('users').get();

  const notifications = [];
  usersSnapshot.forEach(userDoc => {
    const userData = userDoc.data();
    if (userData.fcmToken) {
      const message = {
        notification: {
          title: 'Tarefas de hoje',
          body: `Você tem tarefas pendentes para hoje. Não esqueça de completá-las!`,
        },
        token: userData.fcmToken,
      };
      notifications.push(admin.messaging().send(message));
    }
  });

  await Promise.all(notifications);
  console.log('Notificações enviadas para todos os usuários.');
});
//assistente virtual
exports.getOpenAIResponse = functions.https.onRequest(async (req, res) => {
  try {
    const apiKey = functions.config().openai.key;
    const { prompt } = req.body;
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { "role": "system", "content": "Você é um assistente útil." },
          { "role": "user", "content": `Interprete o seguinte comando e extraia o título da tarefa, a data, o horário de início e término: "${prompt}".` }
        ],
        max_tokens: 550,
      }),
    });

    if (!response.ok) {
      const errorMessage = await response.text();
      throw new Error(`OpenAI API error: ${response.status} - ${errorMessage}`);
    }

    const responseBody = await response.json();
    res.status(200).send(responseBody);
  } catch (error) {
    console.error('Error fetching OpenAI response:', error);
    res.status(500).send(`Erro ao buscar resposta da IA: ${error.message}`);
  }
});
