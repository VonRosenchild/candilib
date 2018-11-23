import nodemailer from 'nodemailer';
import mailMessage from '../util/messageMailManager';
import serverConfig from '../config';
import smtpTransport from 'nodemailer-smtp-transport';

const sendMagicLink = (candidatAurige, token) => {
  const flag = 'CHECK_OK';
  const message = mailMessage(candidatAurige, flag);
  // const INSCRIPTION_OK_MSG = `Bienvenue sur Candilib! </br>\n\r
  //   Vous êtes inscrit sur le site de réservation des candidats libres.</br>\n\r
  //   Voici votre identifiant: ${email}\n`;

  const transporter = nodemailer.createTransport(
    smtpTransport({
      host: serverConfig.smtpServer,
      port: serverConfig.smtpPort,
      secure: false,
      tls: {
        // do not failed with selfsign certificates
        rejectUnauthorized: false,
      },
    }),
  );

  const url = `${serverConfig.host}:${serverConfig.portMail}${serverConfig.authentificationRoute}?token=${encodeURIComponent(token)}&redirect=calendar`;

  const mailOptions = {
    from: serverConfig.mailFrom,
    to: candidatAurige.email,
    subject: `${message.subject}`,
    text: `${message.subject}`,
    html: `<!DOCTYPE html>
      <html>
        <head>
        <title>Email de Candilib</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <meta content="width=device-width">
        <style type="text/css">
        /* Fonts and Content */
        body, td { font-family: 'Helvetica Neue', Arial, Helvetica, Geneva, sans-serif; font-size:14px; color:rgba(0,0,0, 0.54); }
        body { background-color: #ffffff; margin: 0; padding: 0; -webkit-text-size-adjust:none; -ms-text-size-adjust:none; }
        h2{ padding-top:12px; /* ne fonctionnera pas sous Outlook 2007+ */color:rgba(0,0,0, 0.54); font-size:22px; }

        @media only screen and (max-width: 480px) {

          table[class=w275], td[class=w275], img[class=w275] { width:135px !important; }
          table[class=w30], td[class=w30], img[class=w30] { width:10px !important; }
          table[class=w580], td[class=w580], img[class=w580] { width:280px !important; }
          table[class=w640], td[class=w640], img[class=w640] { width:300px !important; }
          img{ height:auto;}
          /*illisible, on passe donc sur 3 lignes */
          table[class=w180], td[class=w180], img[class=w180] {
              width:280px !important;
              display:block;
          }
          td[class=w20]{ display:none; }
        }

        </style>

        </head>
        <body style="margin:20px; padding:0px; -webkit-text-size-adjust:none;">

          <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:rgb(255, 255, 255)" >
              <tbody>
                <tr>
                  <td align="center" bgcolor="#FFFFFF">
                      <table  cellpadding="0" cellspacing="0" border="0">
                        <tbody>
                          <tr>
                              <td class="w640"  width="640" height="10"></td>
                          </tr>
                          <tr>
                              <td class="w640"  width="640" height="10"></td>
                          </tr>
                          <!-- entete -->
                          <tr class="pagetoplogo">
                              <td class="w640"  width="640">
                                <table  class="w640"  width="640" cellpadding="0" cellspacing="0" border="0">
                                  <tbody>
                                      <tr>
                                        <td class="w30"  width="30"></td>
                                        <td  class="w580"  width="580" valign="middle" align="left">
                                        </td>
                                        <td class="w30"  width="30"></td>
                                      </tr>
                                  </tbody>
                                </table>
                              </td>
                          </tr>
                          <!-- contenu -->
                          <tr class="content">
                              <td class="w640" class="w640"  width="640" bgcolor="#ffffff">
                                <table class="w640"  width="640" cellpadding="0" cellspacing="0" border="0">
                                  <tbody>
                                      <tr>
                                        <td  class="w30"  width="30"></td>
                                        <td  align="center" class="w580"  width="580">
                                          <!-- une zone de contenu -->
                                          <table class="w580"  width="580" cellpadding="10" cellspacing="10" border="0">
                                            <tbody>
                                              <tr>
                                                <td>
                                                  <img width="80px" src="https://www.cartaplac.com/images/logo-securite-routiere.jpg" />
                                                </td>
                                                <td class="w580"  width="580" align="center" bgcolor="#64b5f6">
                                                  <h2>
                                                    CANDILIB
                                                  </h2>
                                                </td>
                                              </tr>
                                              <tr>
                                                <td class="article-content" colspan="2">
                                                  ${message.content}
                                                  <br/>
                                                  <p>
                                                  <a href="${url}">
                                                    Vous pouvez vous connecter à Candilb en cliquant sur ce lien
                                                  </a>
                                                  </p>
                                                </td>
                                              </tr>
                                            </tbody>
                                          </table>
                                          <!-- fin zone -->

                                        </td>
                                        <td class="w30" class="w30"  width="30"></td>
                                      </tr>
                                  </tbody>
                                </table>
                              </td>
                          </tr>

                          <!--  separateur horizontal de 15px de haut -->
                          <tr>
                            <td class="w640"  width="640" height="15" bgcolor="#ffffff"></td>
                          </tr>

                          <!-- pied de page -->
                          <tr class="pagebottom">
                              <td class="w640"  width="640">
                                <table class="w640"  width="640" cellpadding="0" cellspacing="0" border="0" bgcolor="#c7c7c7">
                                  <tbody>
                                      <tr>
                                        <td colspan="5" height="10"></td>
                                      </tr>
                                      <tr>
                                        <td class="w30"  width="30"></td>
                                        <td class="w580"  width="580" valign="top">
                                          <p align="right" class="pagebottom-content-left"><span style="color:rgba(0,0,0, 0.54)">&copy; 2018 Candilib</span>
                                          </p>
                                        </td>

                                        <td class="w30"  width="30"></td>
                                      </tr>
                                      <tr>
                                        <td colspan="5" height="10"></td>
                                      </tr>
                                  </tbody>
                                </table>
                              </td>
                          </tr>
                          <tr>
                            <td class="w640"  width="640" height="60"></td>
                          </tr>
                        </tbody>
                      </table>
                  </td>
                </tr>
              </tbody>
          </table>
        </body>
      </html>`,
  };

  transporter.sendMail(mailOptions, (err, info) => {
    if (err) {
      console.log(err); // eslint-disable-line no-console
    } else {
      console.log('MagicLink sent: ' + info.response);
      transporter.close();
    }
    transporter.close();
  });
};

export default sendMagicLink;
