// src/app/models/models.ts

export interface User {
  _id:           string;
  name:          string;
  email:         string;
  role:          'client' | 'freelancer' | 'admin';
  walletBalance: number;
  isBlocked:     boolean;
  createdAt:     string;
  avatar?:       string;
}

export interface Project {
  _id:                string;
  title:              string;
  description:        string;
  budget:             number;
  status:             'open' | 'in_progress' | 'delivered' | 'completed' | 'disputed' | 'refunded';
  escrowStatus?:      string;
  owner:              Partial<User>;
  acceptedFreelancer: Partial<User> | null;
  delivery?:          { link?: string; message?: string; file?: string };
  disputeReason?:     string;
  createdAt:          string;
}

export interface Stats {
  users:    { total: number; clients: number; freelancers: number };
  projects: { total: number; open: number; inProgress: number; delivered: number; completed: number; disputed: number };
  escrow:   { total: number };
}