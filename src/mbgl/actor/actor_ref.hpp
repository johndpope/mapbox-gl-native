#pragma once

#include <mbgl/actor/mailbox.hpp>
#include <mbgl/actor/message.hpp>

#include <memory>

namespace mbgl {

template <class Object>
class ActorRef {
public:
    ActorRef(Object& object_, std::weak_ptr<Mailbox> weakMailbox_)
        : object(object_),
          weakMailbox(std::move(weakMailbox_)) {
    }

    template <typename Fn, class... Args>
    void invoke(Fn fn, Args&&... args) {
        if (auto mailbox = weakMailbox.lock()) {
            mailbox->push(actor::makeMessage(object, fn, std::forward<Args>(args)...));
        }
    }

private:
    Object& object;
    std::weak_ptr<Mailbox> weakMailbox;
};

} // namespace mbgl
