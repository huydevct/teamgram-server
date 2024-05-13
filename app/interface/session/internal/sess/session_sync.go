// Copyright 2022 Teamgram Authors
//  All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Author: teamgramio (teamgram.io@gmail.com)
//

package sess

import (
	"context"

	"github.com/teamgram/proto/mtproto"

	"github.com/zeromicro/go-zero/core/logx"
)

func (c *session) onSyncData(ctx context.Context, obj mtproto.TLObject) {
	// for android, obj maybe is nil
	if obj != nil {
		logx.WithContext(ctx).Infof("genericSession]]>> - session: %s, syncData: %s", c, obj.DebugString())
	} else {
		logx.WithContext(ctx).Infof("genericSession]]>> - session: %s, syncData: nil", c)
	}

	gatewayId := c.getGatewayId()

	if c.isAndroidPush {
		pusMsgId := c.authSessions.getNextNotifyId()
		c.sendPushToQueue(ctx, gatewayId, pusMsgId, androidPushTooLong)
	} else {
		pusMsgId := c.authSessions.getNextPushId()
		c.sendPushToQueue(ctx, gatewayId, pusMsgId, obj)
	}

	if c.sessionOnline() {
		if gatewayId == "" {
			logx.WithContext(ctx).Errorf("gatewayId is empty, send delay...")
		} else {
			c.sendQueueToGateway(ctx, gatewayId)
		}

		//	syncMessage := &pendingMessage{
		//		messageId: nextMessageId(false),
		//		confirm:   true,
		//		// tl:        obj,
		//	}
		//	if c.isAndroidPush {
		//		syncMessage.tl = androidPushTooLong
		//	} else {
		//		syncMessage.tl = obj
		//	}
		//	c.syncMessages = append(c.syncMessages, syncMessage)
		//
		//	log.Debugf("genericSession]]>> - sendPending {sess: {%s}, pushObj: {%s}", c, reflect.TypeOf(obj))
		//	c.sendPendingMessagesToClient(c.getConnId(), c.syncMessages)
		//	c.syncMessages = []*pendingMessage{}
	}
}

func (c *session) onSyncRpcResultData(ctx context.Context, reqMsgId int64, data []byte) {
	// TODO(@benqi):
	// log.Debugf("genericSession]]>> - %v", cntl)
	c.pendingQueue.Remove(reqMsgId)
	gatewayId := c.getGatewayId()
	c.sendPushRpcResultToQueue(gatewayId, reqMsgId, data)
}

func (c *session) onSyncSessionData(ctx context.Context, obj mtproto.TLObject) {
	// TODO(@benqi):
	gatewayId := c.getGatewayId()
	pusMsgId := c.authSessions.getNextPushId()

	c.sendPushToQueue(ctx, gatewayId, pusMsgId, obj)
	c.sendQueueToGateway(ctx, gatewayId)
}
