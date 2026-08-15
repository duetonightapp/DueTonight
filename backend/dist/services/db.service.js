"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prisma = void 0;

let _prismaInstance = null;

exports.prisma = new Proxy({}, {
    get(target, prop) {
        if (!_prismaInstance) {
            try {
                const { PrismaClient } = require("@prisma/client");
                _prismaInstance = new PrismaClient();
            } catch (e) {
                console.warn("Prisma Client initialization warning:", e.message);
                return (...args) => Promise.resolve([]);
            }
        }
        const val = _prismaInstance[prop];
        if (typeof val === 'function') {
            return val.bind(_prismaInstance);
        }
        return val;
    }
});
