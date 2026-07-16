"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("../controllers/auth.controller");
const router = (0, express_1.Router)();
router.get('/microsoft', auth_controller_1.connectMicrosoft);
router.get('/microsoft/callback', auth_controller_1.microsoftCallback);
exports.default = router;
