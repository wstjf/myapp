import 'dart:developer';

import 'package:bili_you/common/api/reply_api.dart';
import 'package:bili_you/common/models/local/reply/reply_item.dart';
import 'package:bili_you/common/models/local/reply/reply_reply_info.dart';
import 'package:bili_you/common/widget/simple_easy_refresher.dart';
import 'package:bili_you/pages/bili_video/widgets/reply/widgets/reply_item.dart';
import 'package:easy_refresh/easy_refresh.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReplyReplyPage extends StatefulWidget {
  const ReplyReplyPage({
    super.key,
    required this.replyId,
    required this.rootId,
    required this.replyType,
  });
  final String replyId;
  final int rootId;
  final ReplyType replyType;

  @override
  State<ReplyReplyPage> createState() => _ReplyReplyPageState();
}

class _ReplyReplyPageState extends State<ReplyReplyPage>
    with AutomaticKeepAliveClientMixin {
  int _pageNum = 1;
  final EasyRefreshController _refreshController = EasyRefreshController(
      controlFinishLoad: true, controlFinishRefresh: true);
  ReplyItem? _rootReply;
  int _upperMid = 0;
  final List<ReplyItem> _replyReplyItems = [];

  Future<bool> _addReplyReply() async {
    late ReplyReplyInfo replyReplyInfo;
    try {
      replyReplyInfo = await ReplyApi.getReplyReply(
          type: widget.replyType,
          oid: widget.replyId,
          rootId: widget.rootId,
          pageNum: _pageNum);
      _rootReply ??= replyReplyInfo.rootReply;
      _upperMid = replyReplyInfo.upperMid;
    } catch (e) {
      log("_addReplyReply:$e");
      return false;
    }
    //更新页码
    //如果当前页不为空的话，下一次加载就进入下一页
    if (replyReplyInfo.replies.isNotEmpty) {
      _pageNum++;
    } else {
      //如果为空的话，下一次加载就返回上一页
      _pageNum--;
    }
    //删除重复项
    final int minIndex = _replyReplyItems.length -
        replyReplyInfo
            .replies.length; //必须要先求n,因为replyReplyInfo.replies是动态删除的,长度会变
    for (var i = _replyReplyItems.length - 1; i >= minIndex; i--) {
      if (i < 0) break;
      replyReplyInfo.replies.removeWhere((element) {
        if (element.rpid == _replyReplyItems[i].rpid) {
          log('same${replyReplyInfo.replies.length}');
          return true;
        } else {
          return false;
        }
      });
    }
    //添加评论
    _replyReplyItems.addAll(replyReplyInfo.replies);
    return true;
  }

  _onLoad() async {
    if (await _addReplyReply()) {
      _refreshController.finishLoad();
      _refreshController.resetFooter();
    } else {
      _refreshController.finishLoad(IndicatorResult.fail);
    }
  }

  _onRefresh() async {
    _replyReplyItems.clear();
    _pageNum = 1;

    if (await _addReplyReply()) {
      _refreshController.finishRefresh();
    } else {
      _refreshController.finishRefresh(IndicatorResult.fail);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SimpleEasyRefresher(
      easyRefreshController: _refreshController,
      onLoad: _onLoad,
      onRefresh: _onRefresh,
      childBuilder: (context, physics) => ListView.builder(
        physics: physics,
        itemCount: _replyReplyItems.length + 1,
        itemBuilder: (context, index) {
          if (_rootReply == null) return const SizedBox();
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  ReplyItemWidget(
                    hasFrontDivider: false,
                    reply: _rootReply!,
                    isUp: _rootReply!.member.mid == _upperMid,
                    showPreReply: false,
                    officialVerifyType: _rootReply!.member.officialVerify.type,
                  ),
                  Divider(
                    color: Theme.of(Get.context!).colorScheme.primaryContainer,
                    thickness: 2,
                  )
                ],
              ),
            );
          }
          return ReplyItemWidget(
            hasFrontDivider: index - 1 > 0,
            reply: _replyReplyItems[index - 1],
            isUp: _replyReplyItems[index - 1].member.mid == _upperMid,
            showPreReply: false,
            officialVerifyType:
                _replyReplyItems[index - 1].member.officialVerify.type,
          );
        },
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
